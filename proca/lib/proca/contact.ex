defmodule Proca.Contact do
  use Ecto.Schema
  import Ecto.Changeset
#   alias Proca.{Repo,Org}

  schema "contacts" do
    field :address, :string
    field :email, :string
    field :payload, :binary
    field :crypto_nonce, :binary
    field :first_name, :string
    field :name, :string
    field :phone, :string
    belongs_to :public_key, Proca.PublicKey
    has_one :consent, Proca.Consent

    many_to_many(
      :signatures,
      Proca.Signature,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    timestamps()
  end


  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :first_name, :email, :phone, :address, :payload])
    |> validate_required([:name, :first_name, :payload])
  end

  @doc "Encrypt this contact changeset for a list of keys.
  Returns lists of Contact records with payload encrypted for each key."
  def encrypt(_contact_ch, []) do
    []
  end

  def encrypt(contact_ch, [pk | public_keys]) do
    enc_ch = case contact_ch do
               %{changes: %{payload: payload}} ->
                 case Proca.Server.Encrypt.encrypt(pk, payload) do
                   {penc, nonce} when is_binary(penc) ->
                     contact_ch
                     |> put_change(:payload, penc)
                     |> put_change(:crypto_nonce, nonce)
                     |> put_assoc(:public_key, pk)
                   {:error, msg} ->
                     add_error(contact_ch, :payload, msg)
                 end
               no_payload ->
                 add_error(no_payload, :payload, "Contact payload required to encrypt")
             end
    [enc_ch | encrypt(contact_ch, public_keys)]
  end
end
