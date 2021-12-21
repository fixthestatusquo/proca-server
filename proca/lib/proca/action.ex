defmodule Proca.Action do
  @moduledoc """
  Record for action done by supporter. Supporter can have many actions, but
  actions can be created without a supporter with intention, to match them later
  to supporter record. This can come handy when we need to create actions for
  user, but will gather personal data later. It is possible to use ref field to
  match action to supporter later.
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.{Action, Supporter, ActionPage}
  alias Proca.Repo
  import Proca.Validations, only: [validate_flat_map: 2]

  schema "actions" do
    field :ref, :binary
    belongs_to :supporter, Proca.Supporter
    field :with_consent, :boolean, default: false

    field :action_type, :string

    field :fields, :map, default: %{}

    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    has_one :donation, Proca.Action.Donation

    field :processing_status, ProcessingStatus, default: :new

    timestamps()
  end

  defp put_supporter_or_ref(ch, supporter = %Supporter{}, _action_page) do
    ch
    |> put_assoc(:supporter, supporter)
  end

  defp put_supporter_or_ref(ch, contact_ref, action_page) when is_bitstring(contact_ref) do
    case Supporter.one(fingerprint: contact_ref, org_id: action_page.org_id) do
      %Supporter{} = supporter ->
        put_assoc(ch, :supporter, supporter)

      nil ->
        change(ch, %{ref: contact_ref, supporter: nil})
    end
  end

  @doc """
  Creates action for supporter. Supporter can be a struct, or reference (binary)
  """
  def build_for_supporter(attrs, supporter, action_page) do
    %Action{}
    |> cast(attrs, [:action_type, :fields])
    |> validate_required([:action_type])
    |> validate_format(:action_type, ~r/^([\w\d_-]+$)/)
    |> validate_flat_map(:fields)
    |> put_supporter_or_ref(supporter, action_page)
    |> put_assoc(:action_page, action_page)
    |> put_change(:campaign_id, action_page.campaign_id)
    |> cast_assoc(:donation, with: &Action.Donation.changeset/2)
    |> check_constraint(:fields, name: :max_fields_size)
  end

  @doc """
  Links actions with a particular ref with provided supporter.
  """
  def link_refs_to_supporter(refs, %Supporter{id: id}) when not is_nil(id) and is_list(refs) do
    from(a in Action, where: is_nil(a.supporter_id) and a.ref in ^refs)
    |> Repo.update_all(set: [supporter_id: id, ref: nil])

    # XXX decouple in a way that lets use do notify
  end

  def get_by_id(action_id) do
    one(id: action_id, preload: [:campaign, [action_page: :org], [supporter: :contacts], :fields])
  end

  def get_by_id_and_ref(action_id, ref) do
    one(id: action_id, contact_ref: ref)
    # from(a in Action,
    #   join: s in Supporter, on: s.id == a.supporter_id,
    #   where: a.id == ^action_id and s.fingerprint == ^ref,
    #   preload: [supporter: s])
    # |> Repo.one()
  end

  def all(q, [{:contact_ref, ref} | kw]) do
    q
    |> join(:inner, [a], s in assoc(a, :supporter))
    |> where([a, s], s.fingerprint == ^ref)
    |> preload([a, s], supporter: s)
    |> all(kw)
  end

  def all(q, [{:action_page, %ActionPage{id: id}} | kw]) do
    q
    |> where([a], a.action_page_id == ^id)
    |> all(kw)
  end

  def all(q, [{:processing_status, status} | kw]) when is_atom(status) do
    all(q, [{:processing_status, [status]} | kw])
  end

  def all(q, [{:processing_status, status} | kw]) when is_list(status) do
    q
    |> where([a], a.processing_status in ^status)
  end

  def clear_transient_fields_query(action = %Action{id: id, fields: fields, action_page: page}) do
    keys = Supporter.Privacy.transient_action_fields(action, page)

    if keys == [] do
      :noop
    else
      fields2 = Map.drop(fields, keys)

      if fields2 == fields do
        :noop
      else
        from(a in Action, where: a.id == ^id, update: [set: [fields: ^fields2]])
      end
    end
  end

  def confirm(action = %Action{}) do
    case action.processing_status do
      :new -> {:error, "not allowed"}
      :confirming -> Repo.update(change(action, processing_status: :accepted))
      :rejected -> {:error, "data already rejected"}
      :accepted -> {:noop, "already accepted"}
      :delivered -> {:noop, "already accepted"}
    end
  end

  def reject(action = %Action{}) do
    case action.processing_status do
      :new -> {:error, "not allowed"}
      :confirming -> Repo.update(change(action, processing_status: :rejected))
      :rejected -> {:noop, "already rejected"}
      :accepted -> Repo.update(change(action, processing_status: :rejected))
      :delivered -> Repo.update(change(action, processing_status: :rejected))
    end
  end
end
