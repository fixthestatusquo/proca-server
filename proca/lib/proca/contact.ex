defmodule Proca.Contact do
  @moduledoc """
  Schema holding personal data (PII). Belongs to action page that collected the
  data, and to organisation which the data is sent to. Contains consent
  information. Can be encrypted. There can be many Contact records per one
  supporter (=per one action)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Contact
  alias Proca.Supporter.Consent

  schema "contacts" do
    belongs_to :supporter, Proca.Supporter

    # Personally Identifiable Information
    field :payload, :binary
    field :crypto_nonce, :binary
    belongs_to :public_key, Proca.PublicKey
    belongs_to :sign_key, Proca.PublicKey

    # Consent
    field :communication_consent, :boolean, default: false
    field :communication_scopes, {:array, :string}, default: []
    field :delivery_consent, :boolean, default: false
    belongs_to :org, Proca.Org

    timestamps()
  end

  @spec build(struct()) :: Ecto.Changeset.t(%Contact{})
  def build(contact_data) when is_struct(contact_data) do
    case Jason.encode(contact_data) do
      {:ok, payload} -> change(%Contact{}, %{payload: payload})
    end
  end

  def spread(_new_contact, []) do
    []
  end

  def spread(new_contact, [consent | rc]) do
    ch =
      new_contact
      |> add_encryption(consent.org)
      |> add_consent(consent)

    [ch | spread(new_contact, rc)]
  end

  def add_consent(contact_ch, %Consent{
        communication_consent: cc,
        communication_scopes: cs,
        delivery_consent: dc,
        org: org
      }) do
    contact_ch
    |> change(communication_consent: cc, communication_scopes: cs, delivery_consent: dc, org: org)
  end

  @spec add_encryption(Ecto.Changeset.t(Contact), %Proca.Org{}) :: Ecto.Changeset.t(Contact)
  def add_encryption(contact_ch, org = %Proca.Org{}) do
    case contact_ch do
      %{changes: %{payload: payload}} ->
        case Proca.Server.Encrypt.encrypt(org, payload) do
          {penc, nonce, enc_id, sign_id} when is_binary(penc) and is_binary(nonce) ->
            contact_ch
            |> put_change(:payload, penc)
            |> put_change(:crypto_nonce, nonce)
            |> put_change(:public_key_id, enc_id)
            |> put_change(:sign_key_id, sign_id)

          {_clear, nil, nil, nil} ->
            contact_ch

          {:error, msg} ->
            add_error(contact_ch, :payload, msg)
        end

      no_payload ->
        add_error(no_payload, :payload, "Contact payload required to encrypt")
    end
  end

  @doc "Encrypt this contact changeset for a list of keys.
  Returns lists of Contact records with payload encrypted for each key."
  def encrypt(_contact_ch, []) do
    []
  end

  @spec encrypt(Ecto.Changeset.t(Contact), [%Proca.PublicKey{}]) :: [Ecto.Changeset.t(Contact)]
  def encrypt(contact_ch, [pk | public_keys]) do
    enc_ch = add_encryption(contact_ch, pk)
    [enc_ch | encrypt(contact_ch, public_keys)]
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end
end
