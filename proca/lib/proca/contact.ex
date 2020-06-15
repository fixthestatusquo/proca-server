defmodule Proca.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Contact

  schema "contacts" do
    field :payload, :binary
    field :crypto_nonce, :binary
    belongs_to :public_key, Proca.PublicKey
    belongs_to :sign_key, Proca.PublicKey
    belongs_to :supporter, Proca.Supporter

    timestamps()
  end

  def build(attrs) when is_map(attrs) do
    external_attrs = attrs |> ProperCase.to_camel_case()
    case JSON.encode(external_attrs) do
      {:ok, payload} -> change(%Contact{}, %{ payload: payload })
    end
  end

  @doc "Encrypt this contact changeset for a list of keys.
  Returns lists of Contact records with payload encrypted for each key."
  def encrypt(_contact_ch, []) do
    []
  end

  @spec encrypt(Ecto.Changeset.t(), [Proca.PublicKey]) :: [Ecto.Changeset.t()]
  def encrypt(contact_ch, [pk | public_keys]) do
    enc_ch =
      case contact_ch do
        %{changes: %{payload: payload}} ->
          case Proca.Server.Encrypt.encrypt(pk, payload) do
            {penc, nonce, sign_id} when is_binary(penc) ->
              contact_ch
              |> put_change(:payload, penc)
              |> put_change(:crypto_nonce, nonce)
              |> put_assoc(:public_key, pk)
              |> put_change(:sign_key_id, sign_id)

            {:error, msg} ->
              add_error(contact_ch, :payload, msg)
          end

        no_payload ->
          add_error(no_payload, :payload, "Contact payload required to encrypt")
      end

    [enc_ch | encrypt(contact_ch, public_keys)]
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end
end
