defmodule Proca.PublicKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "public_keys" do
    field :name, :string
    field :public, :binary
    field :private, :binary
    belongs_to :org, Proca.Org

    timestamps()
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:name, :key])
    |> validate_required([:name, :key])
  end


  def build_for(org) do
    {priv, pub} = Kcl.generate_key_pair
    %Proca.PublicKey{}
    |> cast(%{
          name: "generated",
          private: priv,
          public: pub
            }, [:name, :private, :public])
            |> put_assoc(:org, org)
  end
end
