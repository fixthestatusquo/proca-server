defmodule Proca.ActionPage do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.Repo
  alias Proca.ActionPage

  schema "action_pages" do
    field :locale, :string
    field :url, :string
    field :delivery, :boolean
    belongs_to :campaign, Proca.Campaign
    belongs_to :org, Proca.Org

    field :extra_supporters, :integer, default: 0
    
    timestamps()
  end

  @doc false
  def changeset(action_page, attrs) do
    action_page
    |> cast(attrs, [:url, :locale, :org_id, :extra_supporters])
    |> validate_required([:url, :locale, :org_id])
    |> validate_format(:url, ~r/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+/) 
  end

  def changeset(attrs) do
    changeset(%ActionPage{}, attrs)
  end

  def find(id) do
    Repo.one from a in ActionPage, where: a.id == ^id, preload: [:campaign, :org]
  end

  def data_module(_ap) do
    Proca.Contact.BasicData
  end
end
