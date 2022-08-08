defmodule Proca.Org do
  @moduledoc """
  Represents an organisation in Proca. `Org` can have many `Staffers`, `Campaigns` and `ActionPage`'s.

  Org can have one or more `PublicKey`'s. Only one of them is active at a particular time. Others are expired.
  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]
  alias Ecto.Multi
  alias Proca.Org
  alias Proca.Service.EmailTemplateDirectory
  import Logger

  schema "orgs" do
    field :name, :string
    field :title, :string
    has_many :public_keys, Proca.PublicKey, on_delete: :delete_all
    has_many :staffers, Proca.Staffer, on_delete: :delete_all
    has_many :campaigns, Proca.Campaign, on_delete: :nilify_all
    # XXX
    has_many :action_pages, Proca.ActionPage, on_delete: :nilify_all

    field :contact_schema, ContactSchema, default: :basic
    field :action_schema_version, :integer, default: 2

    # avoid storing transient data in clear
    # XXX rename to a more adequate :strict_privacy
    # XXX also maybe move to campaign level
    field :high_security, :boolean, default: false

    field :doi_thank_you, :boolean, default: false

    # services and delivery options
    has_many :services, Proca.Service, on_delete: :delete_all
    belongs_to :email_backend, Proca.Service
    belongs_to :storage_backend, Proca.Service
    field :email_from, :string

    # supporter confirm in configuration
    field :supporter_confirm, :boolean, default: false
    field :supporter_confirm_template, :string

    # confirming and delivery configuration
    field :custom_supporter_confirm, :boolean, default: false
    field :custom_action_confirm, :boolean, default: false
    field :custom_action_deliver, :boolean, default: false
    field :custom_event_deliver, :boolean, default: false

    belongs_to :event_backend, Proca.Service

    # for processing system events from Proca.Server.Notify
    field :event_processing, :boolean, default: false
    field :system_sqs_deliver, :boolean, default: false

    field :config, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [
      :name,
      :title,
      :contact_schema,
      :email_from,
      :supporter_confirm,
      :supporter_confirm_template,
      :config,
      :high_security,
      :doi_thank_you,
      :custom_supporter_confirm,
      :custom_action_confirm,
      :custom_action_deliver,
      :custom_event_deliver,
      :system_sqs_deliver,
      :event_processing,
      :action_schema_version
    ])
    |> cast_email_backend(org, attrs)
    |> cast_event_backend(org, attrs)
    |> cast_storage_backend(org, attrs)
    |> validate_required([:name, :title])
    |> validate_format(:name, ~r/^[[:alnum:]_-]+$/)
    |> unique_constraint(:name)
    |> Proca.Contact.Input.validate_email(:email_from)
    |> Proca.Service.EmailTemplate.validate_exists(:supporter_confirm_template)
  end

  def cast_email_backend(chset, org, %{email_backend: srv_name})
      when srv_name in [:mailjet, :ses] do
    case Proca.Service.one([name: srv_name, org: org] ++ [:latest]) do
      nil ->
        add_error(chset, :email_backend, "no such service")

      %{id: id} ->
        chset
        |> put_change(:email_backend_id, id)
    end
  end

  def cast_email_backend(chset, _org, %{email_backend: :system}) do
    case Proca.Org.one([:instance] ++ [preload: [:email_backend]]) do
      %{email_backend: %{id: id}} ->
        chset
        |> put_change(:email_backend_id, id)

      _e ->
        add_error(chset, :email_backend, "cannot inherit system service")
    end
  end

  def cast_email_backend(chset, _org, %{email_backend: %Proca.Service{id: id}}) do
    chset
    |> put_change(:email_backend_id, id)
  end

  def cast_email_backend(chset, _org, %{email_backend: nil}) do
    chset
    |> put_change(:email_backend_id, nil)
  end

  def cast_email_backend(ch, _org, %{email_backend: srv_name})
      when is_atom(srv_name) do
    add_error(ch, :email_backend, "service does not support email")
  end

  def cast_email_backend(ch, _org, _a), do: ch

  def cast_event_backend(chset, org, %{event_backend: srv_name})
      when srv_name in [:webhook] do
    case Proca.Service.one([name: srv_name, org: org] ++ [:latest]) do
      nil ->
        add_error(chset, :event_backend, "no such service")

      %{id: id} ->
        chset
        |> put_change(:event_backend_id, id)
    end
  end

  def cast_event_backend(ch, _org, %{event_backend: srv_name})
      when is_atom(srv_name) do
    add_error(ch, :event_backend, "service does not support events")
  end

  def cast_event_backend(ch, _org, _a), do: ch

  def cast_storage_backend(chset, org, %{storage_backend: srv_name})
      when srv_name in [:supabase] do
    case Proca.Service.one([name: srv_name, org: org] ++ [:latest]) do
      nil ->
        add_error(chset, :storage_backend, "no such service")

      %{id: id} ->
        chset
        |> put_change(:storage_backend_id, id)
    end
  end

  def cast_storage_backend(ch, _org, %{storage_backend: srv_name})
      when is_atom(srv_name) do
    add_error(ch, :storage_backend, "service does not support events")
  end

  def cast_storage_backend(ch, _org, _a), do: ch

  def all(q, [{:name, name} | kw]), do: where(q, [o], o.name == ^name) |> all(kw)
  def all(q, [:instance | kw]), do: all(q, [{:name, instance_org_name()} | kw])

  def all(q, [:active_public_keys | kw]) do
    q
    |> join(:left, [o], k in assoc(o, :public_keys), on: k.active)
    |> order_by([o, k], asc: k.inserted_at)
    |> preload([o, k], public_keys: k)
    |> all(kw)
  end

  def delete(org) do
    change(org)
    |> foreign_key_constraint(:action_pages,
      name: :action_pages_org_id_fkey,
      message: "has action pages"
    )
  end

  def get_by_name(name, preload \\ []) do
    one(name: name, preload: preload)
  end

  def get_by_id(id, preload \\ []) do
    one(id: id, preload: preload)
  end

  def instance_org_name do
    Application.get_env(:proca, Proca)[:org_name]
  end

  def list(preloads \\ []) do
    all(preload: preloads)
  end

  @spec active_public_keys([Proca.PublicKey]) :: [Proca.PublicKey]
  def active_public_keys(public_keys) do
    public_keys
    |> Enum.filter(& &1.active)
    |> Enum.sort(fn a, b -> a.inserted_at < b.inserted_at end)
  end

  @spec active_public_keys(Proca.Org) :: Proca.PublicKey | nil
  def active_public_key(org) do
    Proca.Repo.one(from(pk in Ecto.assoc(org, :public_keys), order_by: [asc: pk.id], limit: 1))
  end

  def put_service(%Org{} = org, service), do: put_service(change(org), service)

  def put_service(%Ecto.Changeset{} = ch, %Proca.Service{name: name} = service)
      when name in [:mailjet, :ses, :testmail] do
    ch
    |> put_assoc(:email_backend, service)
  end
end
