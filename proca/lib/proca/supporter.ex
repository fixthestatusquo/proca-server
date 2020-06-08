defmodule Proca.Supporter do
  use Ecto.Schema
  alias Proca.Repo
  alias Proca.{Consent, Supporter, Contact, ActionPage}
  import Ecto.Changeset
  import Ecto.Query

  schema "supporters" do
    has_many :contacts, Proca.Contact
    has_one :consent, Proca.Consent

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

  def from_contact_data(%{valid?: true, changes: attrs}, action_page) do
    %Supporter{}
    |> cast(attrs, [:first_name, :email])  ## <- this list must come from action page pipeline needs
    |> put_assoc(:campaign, action_page.campaign)
    |> put_assoc(:action_page, action_page)
  end

  def maybe_encrypt(contact, recipients) do
    case Proca.Supporter.Privacy.is_encrypted(recipients) do
      {true, keys} -> Contact.encrypt(contact, keys)
      false -> [contact]
    end
  end

  def distribute_personal_data(new_supporter, new_contact, action_page, privacy) do
    with recipients <- Proca.Supporter.Privacy.recipients(action_page, privacy),
         distributed_contacts <- maybe_encrypt(new_contact, recipients),
         consent <- Consent.from_privacy(privacy) do
      new_supporter
      |> put_assoc(:contacts, distributed_contacts)
      |> put_assoc(:consent, consent)
    end
  end

  def privacy_defaults(%{opt_in: _opt_in, lead_opt_in: _lead_opt_in} = p) do
    p
  end

  def privacy_defaults(%{opt_in: _opt_in} = p) do
    Map.put(p, :lead_opt_in, false)
  end

  @doc """
  """
  def create_supporter(action_page, %{contact: contact, privacy: privacy}) do
    data_mod = ActionPage.data_module(action_page)

    with data = %{valid?: true} = data <- apply(data_mod, :from_input, [contact]),
         {new_contact = %{valid?: true}, fpr} <- apply(data_mod, :to_contact, [data, action_page]),
           new_supporter = %{valid?: true} <- from_contact_data(data, action_page)
           |> distribute_personal_data(new_contact, action_page, privacy_defaults(privacy))
           |> put_change(:fingerprint, fpr)
    do
      new_supporter
    else
      invalid_data ->
        {:error, invalid_data}
    end
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
end
