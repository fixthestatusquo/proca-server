defmodule Proca.PublicKey do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.Repo

  schema "public_keys" do
    field :name, :string
    field :public, :binary
    field :private, :binary
    field :expired_at, :utc_datetime
    belongs_to :org, Proca.Org

    timestamps()
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:name, :expired_at, :public, :private])
    |> validate_required([:name, :public])
    |> put_assoc(:org, Map.get(attrs, :org))
  end

  def expire(public_key) do
    changeset(public_key, %{expired_at: DateTime.utc_now()})
  end

  def active_keys_for(org) do
    from(pk in Proca.PublicKey, where: pk.org_id == ^org.id and is_nil(pk.expired_at))
    |> Repo.all
  end

  def build_for(org, name \\ "generated") do
    {priv, pub} = Kcl.generate_key_pair

    %Proca.PublicKey{}
    |> changeset(%{name: name, org: org, public: pub, private: priv})
  end

  def import_private_for(org, private, name \\ "imported") do
    pk = %Proca.PublicKey{}
    |> changeset(%{name: name, org: org})

    case Base.decode64(private) do
      {:ok, key} when is_binary(key) ->
        with public <- Kcl.derive_public_key(key) do
          pk
          |> put_change(:private, key)
          |> put_change(:public, public)
        end
      :error ->
        add_error(pk, :private, "Cannot decode private key using Base64")
    end
  end

  def import_public_for(org, public, name \\ "imported") do
    pk = %Proca.PublicKey{}
    |> changeset(%{name: name, org: org})

    case Base.decode64(public) do
      {:ok, key} when is_binary(key) ->
        pk
        |> put_change(:public, key)
      :error ->
        add_error(pk, :public, "Cannot decode public key using Base64")
    end
  end
end
