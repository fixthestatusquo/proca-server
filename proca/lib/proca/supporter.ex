defmodule Proca.Supporter do
  @moduledoc """
  Supporter is the actor that does actions.
  Has associated contacts, which contain personal data dediacted to every receiving org
  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  alias Proca.Repo
  alias Proca.{Supporter, Contact, ActionPage}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Stage.Support
  import Ecto.Changeset

  schema "supporters" do
    has_many :contacts, Proca.Contact

    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    field :fingerprint, :binary
    has_many :actions, Proca.Action

    field :first_name, :string
    field :email, :string
    field :area, :string

    field :processing_status, ProcessingStatus, default: :new
    field :email_status, EmailStatus, default: :none
    field :email_status_changed, :utc_datetime

    timestamps()
  end

  def changeset(supporter, attrs) do
    ch =
      supporter
      |> cast(attrs, [:email_status])

    case ch.changes do
      %{email_status: _} ->
        change(ch, email_status_changed: DateTime.truncate(DateTime.utc_now(), :second))

      _ ->
        ch
    end
  end

  def new_supporter(data, action_page = %ActionPage{}) do
    %Supporter{}
    |> change(Map.take(data, Supporter.Privacy.cleartext_fields(action_page)))
    |> change(%{fingerprint: Data.fingerprint(data)})
    |> put_assoc(:campaign, action_page.campaign)
    |> put_assoc(:action_page, action_page)
  end

  # @spec add_contacts(Ecto.Changeset.t(Supporter), Ecto.Changeset.t(Contact), %ActionPage{}, %Privacy{}) :: Ecto.Changeset.t(Supporter)
  def add_contacts(
        new_supporter = %Ecto.Changeset{},
        new_contact = %Ecto.Changeset{},
        action_page = %ActionPage{},
        privacy = %Privacy{}
      ) do
    consents = Privacy.consents(action_page, privacy)
    contacts = Contact.spread(new_contact, consents)

    new_supporter
    |> put_assoc(:contacts, contacts)
  end

  def confirm(sup = %Supporter{}) do
    case sup.processing_status do
      :new -> {:error, "not allowed"}
      :confirming -> Repo.update(change(sup, processing_status: :accepted))
      :rejected -> {:error, "supporter data already rejected"}
      :accepted -> {:noop, "supporter data already processed"}
      :delivered -> {:noop, "supporter data already processed"}
    end
  end

  def reject(sup = %Supporter{}) do
    case sup.processing_status do
      :new -> {:error, "not allowed"}
      :confirming -> Repo.update(change(sup, processing_status: :rejected))
      :rejected -> {:noop, "supporter data already rejected"}
      :accepted -> {:noop, "supporter data already processed"}
      :delivered -> {:error, "supporter data already processed"}
    end
  end

  def privacy_defaults(p = %{opt_in: _opt_in, lead_opt_in: _lead_opt_in}) do
    p
  end

  def privacy_defaults(p = %{opt_in: _opt_in}) do
    Map.put(p, :lead_opt_in, false)
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end

  def decode_ref(changeset = %Ecto.Changeset{}, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      base ->
        case base_decode(base) do
          {:ok, val} -> put_change(changeset, field, val)
          :error -> add_error(changeset, field, "Cannot decode from Base64url")
        end
    end
  end

  def handle_bounce(args) do
    case one(action_id: args.id) do
      # ignore a bounce when not found
      nil ->
        {:ok, %Supporter{}}

      supporter ->
        reject(supporter)
        Repo.update!(changeset(supporter, %{email_status: args.reason}))
    end
  end

  def all(q, [{:action_id, a_id} | kw]) do
    import Ecto.Query

    q
    |> join(:inner, [s], a in assoc(s, :actions))
    |> where([s, a], a.id == ^a_id)
    |> all(kw)
  end

  def all(q, [{:fingerprint, fpr} | kw]), do: all(q, [{:contact_ref, fpr} | kw])

  def all(q, [{:contact_ref, fpr} | kw]) do
    import Ecto.Query

    q
    |> where([s], s.fingerprint == ^fpr)
    |> order_by([s], desc: :inserted_at)
    |> all(kw)
  end

  def all(q, [{:org_id, org_id} | kw]) do
    import Ecto.Query

    q
    |> join(:inner, [s], ap in assoc(s, :action_page))
    |> join(:inner, [s, ap], org in assoc(ap, :org))
    |> where([s, ap, org], org.id == ^org_id)
    |> all(kw)
  end

  def all(q, [{:action_page, %ActionPage{id: id}} | kw]) do
    import Ecto.Query

    q
    |> where([a], a.action_page_id == ^id)
    |> all(kw)
  end

  def get_by_action_id(action_id) do
    one(action_id: action_id)
  end

  # XXX rename this to something like "clear_transient_fields"
  def clear_transient_fields_query(supporter) do
    import Ecto.Query

    clear_fields =
      Supporter.Privacy.transient_supporter_fields(supporter.action_page)
      |> Enum.map(fn f -> {f, nil} end)

    from(s in Supporter,
      where: s.id == ^supporter.id,
      update: [set: ^clear_fields]
    )
  end
end
