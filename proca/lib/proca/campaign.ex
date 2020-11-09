defmodule Proca.Campaign do
  @moduledoc """
  Campaign represents a political goal and consists of many action pages. Belongs to one Org (so called "leader org").
  """

  use Ecto.Schema
  alias Proca.{Repo, Campaign, ActionPage}
  import Ecto.Changeset
  import Ecto.Query

  schema "campaigns" do
    field :name, :string
    field :external_id, :integer
    field :title, :string
    field :force_delivery, :boolean
    field :public_actions, {:array, :string}, default: []
    field :config, :map

    belongs_to :org, Proca.Org
    has_many :action_pages, Proca.ActionPage

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :title, :external_id, :config])
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

  def select_by_org(org) do
    from(c in Campaign,
      left_join: ap in ActionPage,
      on: c.id == ap.campaign_id,
      where: ap.org_id == ^org.id or c.org_id == ^org.id
    )
    |> distinct(true)
  end
end
