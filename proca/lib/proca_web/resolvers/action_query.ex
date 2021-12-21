defmodule ProcaWeb.Resolvers.ActionQuery do
  @moduledoc """
  Resolvers for public action lists (recent comments etc.)
  """
  import Ecto.Query
  alias Proca.Repo
  alias Proca.{Action, Campaign}

  @max_list_size 100
  def list_by_action_type(
        campaign = %{id: campaign_id},
        params = %{action_type: action_type},
        _ctx
      ) do
    limit = min(params.limit, @max_list_size)

    select_actions =
      from(a in Action,
        join: c in assoc(a, :campaign),
        where:
          c.id == ^campaign_id and a.action_type == ^action_type and
            a.processing_status in [:accepted, :delivered],
        order_by: [desc: :inserted_at],
        limit: ^limit
      )

    list =
      select_actions
      |> Repo.all()
      |> Enum.map(fn a ->
        %{
          action_id: a.id,
          action_type: a.action_type,
          inserted_at: a.inserted_at,
          custom_fields: Map.take(a.fields, Campaign.public_action_keys(campaign, action_type))
        }
      end)

    field_keys =
      Enum.map(list, fn %{custom_fields: cf} -> Map.keys(cf) end)
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
