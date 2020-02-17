defmodule Proca.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field :campaign, :string
    field :content, :string
    field :medium, :string
    field :source, :string

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:source, :medium, :campaign, :content])
    |> validate_required([:source, :medium, :campaign, :content])
  end
end
