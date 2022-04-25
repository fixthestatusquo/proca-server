defmodule ProcaWeb.Resolvers.Target do
  alias Ecto.Multi
  alias Proca.Target
  alias Proca.TargetEmail
  alias ProcaWeb.Helper

  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Repo

  def upsert_targets(_p, params = %{targets: targets, campaign_id: campaign_id}, _) do
    replace = Map.get(params, :replace, false)

    result =
      Multi.new()
      |> upsert_all(targets, campaign_id)
      |> replace_not_given(campaign_id, replace)
      |> Proca.Repo.transaction()

    case result do
      {:ok, records} ->
        {:ok, pick_targets(records)}

      {:error, {:target, ext_id}, error, _} ->
        target_idx = Enum.find_index(targets, fn %{external_id: eid} -> eid == ext_id end)
        {:error, Helper.format_errors(error, [target_idx, "targets"])}

      {:error, :replace, error, _} ->
        {:error, Helper.format_errors(error)}
    end
  end

  defp pick_targets(result) when is_map(result) do
    Map.values(result)
    |> Enum.filter(fn
      %Target{} -> true
      _ -> false
    end)
  end

  def replace_not_given(multi, _campaign_id, false), do: multi

  def replace_not_given(multi, campaign_id, true) do
    multi
    |> Multi.update(:replace, fn targets ->
      replace =
        Proca.Campaign.one(id: campaign_id, preload: [:targets])
        |> change()
        |> put_assoc(:targets, pick_targets(targets))

      # For each changed replaced target changeset, we need to add a FK information
      %{
        replace
        | changes:
            Map.update(
              replace.changes,
              :targets,
              [],
              fn t ->
                Enum.map(
                  t,
                  &foreign_key_constraint(&1, :messages,
                    name: :messages_target_id_fkey,
                    message: "has messages"
                  )
                )
              end
            )
      }
    end)
  end

  def list(_, %{campaign_id: campaign_id}, _) do
    targets =
      Target
      |> where(campaign_id: ^campaign_id)
      |> preload(:emails)
      |> Repo.all()

    {:ok, targets}
  end

  defp upsert_all(multi, targets, campaign_id) do
    Enum.reduce(targets, multi, fn target, multi ->
      target = Map.put(target, :campaign_id, campaign_id)

      Multi.insert_or_update(multi, {:target, target.external_id}, Target.upsert(target))
    end)
  end
end
