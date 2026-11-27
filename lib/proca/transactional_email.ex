defmodule Proca.TransactionalEmail do
  @moduledoc """
  Role-based definition of a transactional email at one scope.

  A row says, for one `role` at one scope (org, campaign or action page):

  - `state`        - `true` / `false`, `nil` = inherit
  - `mechanism`    - `:own_template` / `:system_template` / `:external_queue`, `nil` = inherit
  - `template_ref` - template name, `nil` = inherit
  - `config`       - per-role settings map, each key inherited separately

  No row = inherit everything.

  ## Resolution

  For an action page the chain is `action_page -> campaign -> org`:

  - campaign: the page's campaign, whoever owns it. Campaign settings apply to
    every page of the campaign, the coordinator's and the partners' alike.
  - org: the org that owns the page. For a partner page that is the partner's
    org, not the campaign owner's.

  Each field resolves on its own: the first non-nil value wins, then the default:

  | field        | default                                          |
  |--------------|--------------------------------------------------|
  | state        | `false`                                          |
  | mechanism    | `:own_template`                                  |
  | template_ref | role name for `:system_template`, else `nil`     |
  | config       | `%{}` (keys merged, most specific wins per key)  |

  The template name is looked up in the page's org for `:own_template` (the
  org that sends the email, so on a partner page a template name set on the
  campaign must exist in the partner's org), and in the instance org for
  `:system_template`. `:external_queue` has no template.
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias Proca.{Repo, Org, Campaign, ActionPage}
  alias Proca.Service.EmailTemplateDirectory
  alias __MODULE__

  @instance_roles [
    :user_confirm_email,
    :user_reset_password,
    :add_staffer,
    :add_partner,
    :launch_page,
    :join_campaign
  ]

  # Allowed config keys per role and the check for each value.
  # Roles not listed here take no config.
  @config_keys %{
    supporter_confirm_reminder1: %{"delay_hours" => :pos_integer},
    supporter_confirm_reminder2: %{"delay_hours" => :pos_integer}
  }

  # most specific first
  @levels [:action_page, :campaign, :org]

  schema "transactional_emails" do
    belongs_to :org, Org
    belongs_to :campaign, Campaign
    belongs_to :action_page, ActionPage

    field :role, TransactionalEmailRole
    field :state, :boolean
    field :mechanism, TransactionalEmailMechanism
    field :template_ref, :string
    field :config, :map

    timestamps()
  end

  defmodule Effective do
    @moduledoc "The resolved definition of a role for a scope."
    defstruct [:role, :state, :mechanism, :template_ref, config: %{}]

    @type t :: %__MODULE__{
            role: atom(),
            state: boolean(),
            mechanism: :own_template | :system_template | :external_queue,
            template_ref: String.t() | nil,
            config: map()
          }
  end

  @type t :: %__MODULE__{}
  @type scope :: %Org{} | %Campaign{} | %ActionPage{}

  def instance_roles, do: @instance_roles
  def instance_role?(role), do: role in @instance_roles

  @doc "Which scope a row belongs to: `:org`, `:campaign` or `:action_page`."
  def level(%TransactionalEmail{action_page_id: ap_id}) when not is_nil(ap_id), do: :action_page
  def level(%TransactionalEmail{campaign_id: c_id}) when not is_nil(c_id), do: :campaign
  def level(%TransactionalEmail{}), do: :org

  # --- Changeset ---------------------------------------------------------

  @doc """
  Changeset for the editable fields. Role and scope ids must already be set on
  the struct (see `set/3`), because they identify the row.
  """
  def changeset(%TransactionalEmail{} = te, attrs) do
    te
    |> cast(attrs, [:state, :mechanism, :template_ref, :config])
    |> validate_required([:org_id, :role])
    |> update_change(:config, &normalize_config/1)
    |> update_change(:template_ref, &blank_to_nil/1)
    |> validate_length(:template_ref, max: 255)
    |> validate_mechanism()
    |> validate_config()
    |> check_constraint(:action_page_id,
      name: :one_scope,
      message: "a row has either a campaign or an action page, not both"
    )
    |> unique_constraint(:role, name: :transactional_emails_role_scope_index)
  end

  defp validate_mechanism(cs) do
    role = get_field(cs, :role)

    validate_change(cs, :mechanism, fn :mechanism, mechanism ->
      if mechanism == :external_queue and role != :supporter_confirm do
        [mechanism: "external_queue is only valid for supporter_confirm"]
      else
        []
      end
    end)
  end

  defp validate_config(cs) do
    role = get_field(cs, :role)

    validate_change(cs, :config, fn :config, config ->
      config_errors(role, Map.get(@config_keys, role), config)
    end)
  end

  defp config_errors(_role, nil, config) when config == %{}, do: []
  defp config_errors(role, nil, _config), do: [config: "is not supported for role #{role}"]

  defp config_errors(role, spec, config) do
    Enum.flat_map(config, fn {key, value} ->
      case Map.fetch(spec, key) do
        :error -> [config: "unknown key #{key} for role #{role}"]
        {:ok, check} -> check_config_value(key, check, value)
      end
    end)
  end

  # nil = inherit this key
  defp check_config_value(_key, _check, nil), do: []
  defp check_config_value(_key, :pos_integer, v) when is_integer(v) and v > 0, do: []

  defp check_config_value(key, :pos_integer, _v),
    do: [config: "#{key} must be a positive integer"]

  defp normalize_config(nil), do: nil

  defp normalize_config(config) when is_map(config),
    do: Map.new(config, fn {k, v} -> {to_string(k), v} end)

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(s), do: s

  # Instance-only roles: only at org scope, only on the instance org.
  defp validate_scope(cs, scope) do
    role = get_field(cs, :role)

    cond do
      not instance_role?(role) ->
        cs

      match?(%Org{}, scope) and scope.name == Org.instance_org_name() ->
        cs

      true ->
        add_error(cs, :role, "#{role} can only be set on the instance org")
    end
  end

  # --- Writing -------------------------------------------------------------

  @doc """
  Insert or update the row for `role` at `scope` with `attrs`
  (`:state`, `:mechanism`, `:template_ref`, `:config`; nil = inherit).
  """
  @spec set(scope(), atom(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def set(scope, role, attrs) when is_atom(role) and is_map(attrs) do
    if role in TransactionalEmailRole.__valid_values__() do
      (get(scope, role) || struct(TransactionalEmail, Map.put(scope_ids(scope), :role, role)))
      |> changeset(attrs)
      |> validate_scope(scope)
      |> Repo.insert_or_update()
    else
      {:error, change(%TransactionalEmail{}) |> add_error(:role, "is invalid")}
    end
  end

  @doc "Remove the row for `role` at `scope` (back to inheriting everything)."
  @spec clear(scope(), atom()) :: :ok
  def clear(scope, role) do
    case get(scope, role) do
      nil -> :ok
      te -> with {:ok, _} <- Repo.delete(te), do: :ok
    end
  end

  @doc "The row stored for `role` at exactly this `scope`, or nil."
  def get(scope, role) do
    ids = scope_ids(scope)

    from(te in TransactionalEmail, where: te.role == ^role)
    |> where_scope(ids)
    |> Repo.one()
  end

  defp scope_ids(%Org{id: id}), do: %{org_id: id, campaign_id: nil, action_page_id: nil}

  defp scope_ids(%Campaign{id: id, org_id: org_id}),
    do: %{org_id: org_id, campaign_id: id, action_page_id: nil}

  defp scope_ids(%ActionPage{id: id, org_id: org_id}),
    do: %{org_id: org_id, campaign_id: nil, action_page_id: id}

  defp where_scope(q, %{action_page_id: ap_id}) when not is_nil(ap_id),
    do: from(te in q, where: te.action_page_id == ^ap_id)

  defp where_scope(q, %{campaign_id: c_id}) when not is_nil(c_id),
    do: from(te in q, where: te.campaign_id == ^c_id)

  defp where_scope(q, %{org_id: org_id}),
    do:
      from(te in q,
        where: te.org_id == ^org_id and is_nil(te.campaign_id) and is_nil(te.action_page_id)
      )

  # --- Resolution ----------------------------------------------------------

  @doc """
  The stored rows for `role` along the resolution chain of `scope`, most
  specific first. Only scopes that have a row appear.

  - org         -> [org]
  - campaign    -> [campaign, campaign's org]
  - action page -> [action_page, campaign, action page's org]
  """
  @spec chain(atom(), scope()) :: [t()]
  def chain(role, scope) do
    condition = dynamic([te], te.role == ^role and ^chain_condition(scope))

    from(te in TransactionalEmail, where: ^condition)
    |> Repo.all()
    |> Enum.sort_by(&Enum.find_index(@levels, fn l -> l == level(&1) end))
  end

  defp chain_condition(%Org{id: org_id}), do: org_row(org_id)

  defp chain_condition(%Campaign{id: c_id, org_id: org_id}),
    do: dynamic([te], te.campaign_id == ^c_id or ^org_row(org_id))

  defp chain_condition(%ActionPage{id: ap_id, org_id: org_id, campaign_id: c_id}) do
    ap_or_org = dynamic([te], te.action_page_id == ^ap_id or ^org_row(org_id))

    case c_id do
      nil -> ap_or_org
      c_id -> dynamic([te], te.campaign_id == ^c_id or ^ap_or_org)
    end
  end

  defp org_row(org_id),
    do:
      dynamic(
        [te],
        te.org_id == ^org_id and is_nil(te.campaign_id) and is_nil(te.action_page_id)
      )

  @doc "Resolve `role` for `scope` to its effective definition (see moduledoc)."
  @spec effective(atom(), scope()) :: Effective.t()
  def effective(role, scope), do: resolve(role, chain(role, scope))

  @doc "Resolve an already fetched chain (most specific first)."
  @spec resolve(atom(), [t()]) :: Effective.t()
  def resolve(role, rows) do
    state = first_set(rows, :state) || false
    mechanism = first_set(rows, :mechanism) || :own_template

    template_ref =
      case mechanism do
        :external_queue -> nil
        :system_template -> first_set(rows, :template_ref) || Atom.to_string(role)
        :own_template -> first_set(rows, :template_ref)
      end

    config =
      rows
      |> Enum.reverse()
      |> Enum.reduce(%{}, fn row, acc ->
        set_keys = for {k, v} <- row.config || %{}, not is_nil(v), into: %{}, do: {k, v}
        Map.merge(acc, set_keys)
      end)

    %Effective{
      role: role,
      state: state,
      mechanism: mechanism,
      template_ref: template_ref,
      config: config
    }
  end

  # state false is a value, not "unset", so find_value would skip it
  defp first_set(rows, field) do
    rows |> Enum.map(&Map.get(&1, field)) |> Enum.find(&(not is_nil(&1)))
  end

  @doc """
  Is `role` switched on for `scope` and has something to send with
  (a template name, or the external queue)? Does not check that the template exists;
  `template/3` does.
  """
  @spec enabled?(atom(), scope()) :: boolean()
  def enabled?(role, scope), do: configured?(effective(role, scope))

  defp configured?(%Effective{state: true, mechanism: :external_queue}), do: true
  defp configured?(%Effective{state: true, template_ref: ref}) when is_binary(ref), do: true
  defp configured?(%Effective{}), do: false

  @doc """
  Find the template to send for `role` at `scope`.

  Returns `{:ok, template, org}` (org = where the template lives), `:off`,
  `:external_queue`, or `:not_found` (on, but no template name or no such template).
  """
  @spec template(atom(), scope(), String.t() | nil) ::
          {:ok, %Proca.Service.EmailTemplate{}, %Org{}} | :off | :external_queue | :not_found
  def template(role, scope, locale \\ nil) do
    case effective(role, scope) do
      %Effective{state: false} ->
        :off

      %Effective{mechanism: :external_queue} ->
        :external_queue

      %Effective{template_ref: nil} ->
        :not_found

      %Effective{mechanism: mechanism, template_ref: ref} ->
        org = template_org(mechanism, scope)

        case EmailTemplateDirectory.by_name_reload(org, ref, locale) do
          {:ok, tmpl} -> {:ok, tmpl, org}
          :not_found -> :not_found
        end
    end
  end

  defp template_org(:system_template, _scope), do: Org.one([:instance])
  defp template_org(:own_template, %Org{} = org), do: org
  defp template_org(:own_template, %{org: %Org{} = org}), do: org
  defp template_org(:own_template, %{org_id: org_id}), do: Org.one(id: org_id)
end
