defmodule ProcaWeb.Resolvers.ActionQuery do
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Repo
  alias Proca.{Action, Field, Campaign, ActionPage}

  alias ProcaWeb.Helper

  def actions_for_campaign(%{campaign_id: campaign_id}) do
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

  def actions_for_campaign(%{action_page_id: action_page_id}) do
    campaign_id = from(ap in ActionPage, where: ap.id == ^action_page_id, select: ap.campaign_id) |> Repo.one()

    actions_for_campaign(%{campaign_id: campaign_id})
  end

  def actions_for_campaign(%{}) do
    {:error, "Provide either campaign_id or action_page_id of queried campaign"}
  end

  @max_list_size 100
  def list_by_action_type(_parent, %{action_type: action_type} = params, _ctx) do
    limit = Map.get(params, :limit, 10)
    limit = max(limit, @max_list_size)

    case actions_for_campaign(params) do
      {:ok, query} ->

        list = query
        |> where([a, c], a.action_type == ^action_type)
        |> order_by([a, c], desc: a.inserted_at)
        |> limit([a, c], ^limit)
        |> select([a, c], a)
        |> Repo.all()
        |> Enum.map(fn a ->
          %{action_type: a.action_type,
            inserted_at: a.inserted_at,
            fields: Enum.map(a.fields, &Map.take(&1, [:key, :value]))}
        end)

        field_keys = Enum.map(list, fn %{fields: fields} -> Enum.map(fields, &Map.get(&1, :key)) end)
        |> List.flatten()
        |> MapSet.new()
        |> MapSet.to_list()

        {:ok, %{
            list: list,
            field_keys: field_keys
         }}

      {:error, msg} -> {:error, msg}
    end
    
  end
end
