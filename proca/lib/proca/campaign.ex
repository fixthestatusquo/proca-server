defmodule Proca.Campaign do
  @moduledoc """
  Campaign represents a political goal and consists of many action pages. Belongs to one Org (so called "leader org").
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  alias Proca.{Repo, Campaign, ActionPage, Org}
  alias Ecto.Multi
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]

  schema "campaigns" do
    field :name, :string
    field :external_id, :integer
    field :title, :string
    field :force_delivery, :boolean, default: false
    field :public_actions, {:array, :string}, default: []
    field :transient_actions, {:array, :string}, default: []
    field :contact_schema, ContactSchema, default: :basic
    field :config, :map, default: %{}

    belongs_to :org, Proca.Org
    has_many :action_pages, Proca.ActionPage
    has_many :targets, Proca.Target, on_delete: :delete_all
    has_one :mtt, Proca.MTT, on_delete: :delete_all, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs) do
    assocs = Map.take(attrs, [:org])

    campaign
    |> cast(attrs, [:name, :title, :external_id, :config, :contact_schema])
    |> cast_assoc(:mtt)
    |> validate_required([:name, :title, :contact_schema])
    |> change(assocs)
    |> validate_format(:name, ~r/^([\w\d_-]+$)/)
    |> unique_constraint(:name)
  end

  def upsert(org, attrs = %{external_id: id}) when not is_nil(id) do
    (one(org: org, external_id: id) ||
       %Campaign{contact_schema: org.contact_schema, org_id: org.id})
    |> changeset(attrs)
  end

  def upsert(org, attrs = %{name: cname}) do
    (one(org: org, name: cname) || %Campaign{contact_schema: org.contact_schema, org_id: org.id})
    |> changeset(attrs)
  end

  def all(queryable, [{:org, %Org{id: org_id}} | criteria]) do
    queryable
    |> where([c], c.org_id == ^org_id)
    |> all(criteria)
  end

  def all(queryable, [{:org_name, org_name} | criteria]) do
    case Org.one(name: org_name) do
      nil -> where(queryable, [c], false) |> all(criteria)
      org -> all(queryable, [{:org, org} | criteria])
    end
  end

  def all(queryable, [{:name, name} | criteria]) do
    queryable
    |> where([c], c.name == ^name)
    |> all(criteria)
  end

  def all(queryable, [{:external_id, id} | criteria]) do
    queryable
    |> where([c], c.external_id == ^id)
    |> all(criteria)
  end

  def all(queryable, [:with_local_pages | criteria]) do
    queryable
    |> join(:left, [c], a in assoc(c, :action_pages), on: a.org_id == c.org_id)
    |> order_by([c, a], desc: a.id)
    |> preload([c, a], [:org, action_pages: a])
    |> all(criteria)
  end

  def all(queryable, [{:title_like, title} | criteria]) do
    queryable
    |> where([c], like(c.title, ^title))
    |> all(criteria)
  end

  def delete(%Multi{} = multi, %Campaign{} = campaign) do
    %{action_pages: owned_pages} = one([id: campaign.id] ++ [:with_local_pages])

    owned_pages
    |> Enum.reduce(multi, fn page, m ->
      ActionPage.delete(m, page)
    end)
    |> Multi.delete(
      {:campaign, campaign.id},
      change(campaign)
      |> foreign_key_constraint(:action_pages,
        name: :action_pages_campaign_id_fkey,
        message: "has action pages"
      )
    )
  end

  def delete(%Campaign{} = campaign) do
    Multi.new()
    |> delete(campaign)
  end

  def get(crit) when is_list(crit), do: one(crit ++ [preload: [:org]])

  # XXX replace when we have Partnership
  @doc "Select campaigns where org is lead or partner"
  def select_by_org(org) do
    from(c in Campaign,
      left_join: ap in ActionPage,
      on: c.id == ap.campaign_id,
      where: ap.org_id == ^org.id or c.org_id == ^org.id
    )
    |> distinct(true)
  end

  def get_with_local_pages(campaign_id) when is_integer(campaign_id) do
    one([id: campaign_id] ++ [:with_local_pages])
  end

  def get_with_local_pages(campaign_name) when is_bitstring(campaign_name) do
    one([name: campaign_name] ++ [:with_local_pages])
  end

  def public_action_keys(%Campaign{public_actions: public_actions}, action_type)
      when is_bitstring(action_type) do
    public_actions
    |> Enum.map(fn p -> String.split(p, ":") end)
    |> Enum.map(fn [at, f | _] -> if at == action_type, do: f, else: nil end)
    |> Enum.reject(&is_nil/1)
  end
end
