defmodule Proca.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaigns" do
    field :name, :string
    field :title, :string
    field :org_id, :id

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :title])
    |> validate_required([:name, :title])
  end
end
