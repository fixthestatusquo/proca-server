defmodule Proca.Org do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "orgs" do
    field :name, :string
    field :title, :string
    has_many :public_keys, Proca.PublicKey

    timestamps()
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :title])
    |> validate_required([:name, :title])
  end

  def get_by_name(name, preload \\ []) do
    Proca.Repo.one from o in Proca.Org, where: o.name == ^name, preload: ^preload
  end
end
