defmodule Proca.Campaign do
  use Ecto.Schema
  alias Proca.{Repo,Campaign}
  import Ecto.Changeset

  schema "campaigns" do
    field :name, :string
    field :external_id, :integer
    field :title, :string
    field :force_delivery, :boolean

    belongs_to :org, Proca.Org
    has_many :action_pages, Proca.ActionPage

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :title])
    |> validate_required([:name, :title])
    |> validate_format(:name, ~r/^([\w\d_-]+$)/)
  end

  def upsert(org, attrs = %{external_id: id}) when not is_nil(id) do
    (Repo.get_by(Campaign, external_id: id, org_id: org.id) || %Campaign{})
    |> Campaign.changeset(attrs)
    |> put_change(:org_id, org.id)
  end

  def upsert(org, attrs = %{name: cname}) do
    (Repo.get_by(Campaign, name: cname, org_id: org.id) || %Campaign{})
    |> Campaign.changeset(attrs)
    |> put_change(:org_id, org.id)
  end
end
