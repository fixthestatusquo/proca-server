defmodule Proca.PublicKey do
  @moduledoc """
  Keypair for encyrption of personal data
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.Repo
  alias Proca.{PublicKey, Org}

  @derive {Inspect, only: [:id, :name, :org, :active, :expired]}

  schema "public_keys" do
    field :name, :string
    field :public, :binary
    field :private, :binary
    field :active, :boolean, default: false
    field :expired, :boolean, default: false
    belongs_to :org, Proca.Org

    timestamps()
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:name, :active, :expired, :public, :private])
    |> validate_required([:name, :public, :active, :expired])
    |> validate_bit_size(:public, 256)
    |> validate_bit_size(:private, 256)
  end

  def expire(public_key) do
    change(public_key, expired: true, active: false)
  end

  def all(q, [{:org, %Org{id: org_id}} | kw]) do
    q
    |> where([pk], pk.org_id == ^org_id)
    |> all(kw)
  end

  def all(q, [:active | kw]) do
    q
    |> order_by([pk], desc: pk.inserted_at)
    |> where([pk], pk.active)
    |> distinct([pk], pk.org_id)
    |> all(kw)
  end

  @spec active_key_for(%Proca.Org{}) :: %PublicKey{} | nil
  def active_key_for(org) do
    one([:active] ++ [org: org, preload: []])
  end

  def active_keys(preload \\ []) do
    all([:active] ++ [preload: preload])
  end

  @spec activate_for(Org, integer) :: Ecto.Multi
  def activate_for(%Org{id: org_id}, id) when is_number(id) do
    alias Ecto.Multi

    Multi.new()
    |> Multi.update_all(
      :keys,
      fn _ ->
        from(pk in PublicKey,
          where: pk.org_id == ^org_id and not pk.expired,
          update: [set: [active: fragment("id = ?", ^id)]]
        )
      end,
      []
    )
    |> Multi.run(:active_key, fn _repo, _ -> {:ok, PublicKey.one(id: id, preload: [:org])} end)
  end

  def build_for(org, name \\ "generated") do
    {priv, pub} = Kcl.generate_key_pair()

    %Proca.PublicKey{}
    |> changeset(%{name: name, public: pub, private: priv})
    |> put_assoc(:org, org)
  end

  def import_private_for(org, private, name \\ "imported") do
    pk =
      %Proca.PublicKey{}
      |> changeset(%{name: name, org: org})

    case base_decode(private) do
      {:ok, key} when is_binary(key) ->
        with public <- Kcl.derive_public_key(key) do
          pk
          |> put_change(:private, key)
          |> put_change(:public, public)
        end

      :error ->
        add_error(pk, :private, "Cannot decode private key using Base64url (RFC4648, no padding)")
    end
  end

  def import_public_for(org, public, name \\ "imported") do
    case base_decode(public) do
      {:ok, key} when is_binary(key) ->
        %Proca.PublicKey{}
        |> changeset(%{name: name, public: key})
        |> put_assoc(:org, org)

      :error ->
        %Proca.PublicKey{}
        |> changeset(%{name: name, public: public})
        |> add_error(:public, "Cannot decode public key using Base64")
    end
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end

  def base_decode_changeset(ch) do
    [:public, :private]
    |> Enum.reduce(ch, fn f, ch ->
      case get_change(ch, f) do
        nil ->
          ch

        encoded ->
          case base_decode(encoded) do
            {:ok, decoded} -> change(ch, %{f => decoded})
            :error -> add_error(ch, f, "must be Base64url encoded")
          end
      end
    end)
  end

  def validate_bit_size(ch, field, size) do
    case get_field(ch, field) do
      nil ->
        ch

      val ->
        if bit_size(val) == size do
          ch
        else
          add_error(ch, field, "must by #{size} bits")
        end
    end
  end

  def filter(query, criteria) when is_map(criteria) do
    filter(query, Map.to_list(criteria))
  end

  def filter(query, []) do
    query
  end

  def filter(query, [{:id, id} | c]) do
    query
    |> where([pk], pk.id == ^id)
    |> filter(c)
  end

  def filter(query, [{:active, active?} | c]) do
    query
    |> where([pk], pk.active == ^active?)
    |> filter(c)
  end

  def filter(query, [{:public, pub_encoded} | c]) do
    case base_decode(pub_encoded) do
      {:ok, pub} -> where(query, [pk], pk.public == ^pub)
      :error -> query
    end
    |> filter(c)
  end
end
