defmodule ProcaWeb.Resolvers.ActionQuery do
  @moduledoc """
  Resolvers for public action lists (recent comments etc.)
  """
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Action

  @max_list_size 100
  def list_by_action_type(%{id: campaign_id, public_actions: public_actions}, params = %{action_type: action_type}, _ctx) do
    limit = min(params.limit, @max_list_size)


    select_actions = from(a in Action,
      join: c in assoc(a, :campaign),
      where: c.id == ^campaign_id and a.action_type == ^action_type and a.processing_status in [:accepted, :delivered],
      order_by: [desc: :inserted_at],
      limit: ^limit,
      select: a.id
    )

    query = from(a in Action,
      join: f in assoc(a, :fields),
      where: a.id in subquery(select_actions),
      where: fragment("? || ':' || ?", a.action_type, f.key) in ^public_actions,
      preload: [fields: f]
    )

    # from(a in Action,
    #   join: c in assoc(a, :campaign),
    #   join: f in assoc(a, :fields),
    #   where: c.id == ^campaign_id,
    #   where: fragment("? || ':' || ?", a.action_type, f.key) in c.public_actions,
    #   preload: [:fields]

    list = query
    |> Repo.all()
    |> Enum.map(fn a -> %{
                        action_id: a.id,
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
