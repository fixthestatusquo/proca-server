defmodule Proca.Signature do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.{Org,Consent,Signature,Contact}

  schema "signatures" do
    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source
    
    many_to_many(
      :contacts,
      Proca.Contact,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(signature, attrs) do
    signature
    |> cast(attrs, [])
    |> validate_required([])
  end

  def maybe_encrypt(contact, [pk]) do
    Contact.encrypt(contact, [pk])
  end

  def maybe_encrypt(contact, []) do
    [contact]
  end

  def build(contact, action_page, consents) do
    # could be 2 consents here for AP and Camp owners...
    with keys <- Org.get_public_keys(action_page.org) |> Org.active_public_keys(),
         [cch] <- maybe_encrypt(contact, keys), 
         cons <- Consent.from_opt_in(consents.opt_in),
         cch2 <- put_assoc(cch, :consent, cons)
      do
      changeset(%Signature{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [cch2])
    end
  end
end
