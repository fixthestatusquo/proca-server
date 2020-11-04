defmodule Proca.Supporter do
  use Ecto.Schema
  alias Proca.Repo
  alias Proca.{Supporter, Contact, ActionPage}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  import Ecto.Changeset
  import Ecto.Query

  schema "supporters" do
    has_many :contacts, Proca.Contact

    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    field :fingerprint, :binary
    has_many :actions, Proca.Action

    field :first_name, :string
    field :email, :string

    field :processing_status, ProcessingStatus, default: :new

    timestamps()
  end

  @doc false
  def changeset(supporter, attrs) do
    supporter
    |> cast(attrs, [])
    |> validate_required([])
  end

  @spec new_supporter(struct(), ActionPage) :: Ecto.Changeset.t(Supporter)
  def new_supporter(data, action_page) do
    %Supporter{}
    |> change(Map.take(data, ActionPage.kept_personalization_fields(action_page)))
    |> change(%{fingerprint: Data.fingerprint(data)})
    |> put_assoc(:campaign, action_page.campaign)
    |> put_assoc(:action_page, action_page)
  end

  @spec add_contacts(Ecto.Changeset.t, Ecto.Changeset.t, ActionPage, Privacy) :: Ecto.Changeset.t
  def add_contacts(new_supporter, new_contact, action_page, privacy) do
    with consents <- Proca.Supporter.Privacy.consents(action_page, privacy),
         contacts <- Contact.spread(new_contact, consents) do
      new_supporter
      |> put_assoc(:contacts, contacts)
    end
  end

  def privacy_defaults(%{opt_in: _opt_in, lead_opt_in: _lead_opt_in} = p) do
    p
  end

  def privacy_defaults(%{opt_in: _opt_in} = p) do
    Map.put(p, :lead_opt_in, false)
  end

  @doc "Returns %Supporter{} or nil"
  def find_by_fingerprint(fingerprint, org_id) do
    query =
      from(s in Supporter,
        join: ap in ActionPage,
        on: s.action_page_id == ap.id,
        where: ap.org_id == ^org_id and s.fingerprint == ^fingerprint,
        order_by: [desc: :inserted_at],
        limit: 1,
        preload: [:contacts]
      )

    Repo.one(query)
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end

  def transient_fields(supporter) do
    from(s in Supporter, where: s.id == ^supporter.id, update: [set: [first_name: nil, email: nil]])
  end
end
