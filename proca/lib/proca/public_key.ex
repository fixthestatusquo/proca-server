defmodule Proca.PublicKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "public_keys" do
    field :key, :string
    field :name, :string
    field :org_id, :id

    timestamps()
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:name, :key])
    |> validate_required([:name, :key])
  end
end
