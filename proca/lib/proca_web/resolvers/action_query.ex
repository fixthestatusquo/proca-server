defmodule ProcaWeb.Resolvers.ActionQuery do
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Repo
  alias Proca.{Action, Field, Campaign, ActionPage}

  alias ProcaWeb.Helper

  def actions_for_campaign(_, %{campaign_id: campaign_id}, _) do
    {
      :ok,
      from(a in Action,
        join: c in assoc(a, :campaign),
        join: f in assoc(a, :fields),
        where: c.id == ^campaign_id,
        where: fragment("? || ':' || ?", a.action_type, f.key) in c.public_actions,
        preload: [:fields])
    }
  end

  def actions_for_campaign(a, %{action_page_id: action_page_id}, b) do
    campaign_id = from(ap in ActionPage, where: ap.id == ^action_page_id, select: ap.campaign_id) |> Repo.one()

    actions_for_campaign(a, %{campaign_id: campaign_id}, b)
  end

  def actions_for_campaign(_, %{}, resolution) do
    {:error, "Provide either campaign_id or action_page_id of queried campaign"}
  end

  @max_list_size 100
  def list_by_action_type(query, %{action_type: action_type} = params, _ctx) do
    limit = Map.get(params, :limit, 10)
    limit = max(limit, @max_list_size)

    data = query
    |> where([a,c], a.action_type == ^action_type)
    |> order_by([a,c], desc: a.inserted_at)
    |> limit([a,c], ^limit)
    |> select([a,c], a)
    |> Repo.all()
    |> Enum.map(fn a ->
      %{action_type: a.action_type, fields: Enum.map(a.fields, &Map.take(&1, [:key, :value]))}
    end)

    {:ok, data}
  end
end
