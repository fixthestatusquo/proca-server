defmodule Proca.ActionPage do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.Repo

  schema "action_pages" do
    field :locale, :string
    field :url, :string
    belongs_to :campaign, Proca.Campaign
    belongs_to :org, Proca.Org
    
    timestamps()
  end

  @doc false
  def changeset(action_page, attrs) do
    action_page
    |> cast(attrs, [:url, :locale])
    |> validate_required([:url, :locale])
  end

  def find(id) do
    Repo.one from a in Proca.ActionPage, where: a.id == ^id, preload: [:campaign, :org]
  end

  def data_module(_ap) do
    Proca.Contact.BasicData
  end
end
