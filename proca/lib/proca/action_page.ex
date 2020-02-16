defmodule Proca.ActionPage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "action_pages" do
    field :locale, :string
    field :url, :string
    field :campaign_id, :id

    timestamps()
  end

  @doc false
  def changeset(action_page, attrs) do
    action_page
    |> cast(attrs, [:url, :locale])
    |> validate_required([:url, :locale])
  end
end
