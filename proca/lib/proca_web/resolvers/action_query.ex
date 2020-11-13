defmodule ProcaWeb.Resolvers.ActionQuery do
  @moduledoc """
  Resolvers for public action lists (recent comments etc.)
  """
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Action

  def actions_for_campaign(campaign_id) do
    from(a in Action,
      join: c in assoc(a, :campaign),
      join: f in assoc(a, :fields),
      where: c.id == ^campaign_id,
      where: fragment("? || ':' || ?", a.action_type, f.key) in c.public_actions,
      preload: [:fields]
    )
  end

  @max_list_size 100
  def list_by_action_type(%{id: campaign_id}, params = %{action_type: action_type}, _ctx) do
    limit = Map.get(params, :limit, 10)
    limit = max(limit, @max_list_size)

    query =  actions_for_campaign(campaign_id)
    list = query
    |> where([a, c], a.action_type == ^action_type)
    |> order_by([a, c], desc: a.inserted_at)
    |> limit([a, c], ^limit)
    |> select([a, c], a)
    |> Repo.all()
    |> Enum.map(fn a -> %{
                        action_type: a.action_type,
                        inserted_at: a.inserted_at,
                        fields: Enum.map(a.fields, &Map.take(&1, [:key, :value]))
                    } end)

    field_keys =
      Enum.map(list, fn %{fields: fields} -> Enum.map(fields, &Map.get(&1, :key)) end)
      |> List.flatten()
      |> MapSet.new()
      |> MapSet.to_list()

    {:ok,
     %{
       list: list,
       field_keys: field_keys
     }}
  end
end
