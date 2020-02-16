defmodule Proca.Org do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orgs" do
    field :name, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :title])
    |> validate_required([:name, :title])
  end
end
