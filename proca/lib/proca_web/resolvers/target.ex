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
      |> delete_rest(campaign_id, replace)
      |> Proca.Repo.transaction(timeout: 120_000)

    case result do
      {:ok, records} ->
        {:ok, pick_targets(records)}

      {:error, {:target, ext_id}, error, _} ->
        target_idx = Enum.find_index(targets, fn %{external_id: eid} -> eid == ext_id end)
        {:error, Helper.format_errors(error, [target_idx, "targets"])}

      {:error, :delete_rest, error, _} ->
        {:error, Helper.format_errors(error, [get_field(error, :id), "targets"])}
    end
  end

  defp pick_targets(result) when is_map(result) do
    Map.values(result)
    |> Enum.filter(fn
      %Target{} -> true
      _ -> false
    end)
  end

  def delete_rest(multi, _campaign_id, false), do: multi

  def delete_rest(multi, campaign_id, true) do
    multi
    |> Multi.run(:delete_rest, fn repo, targets ->
      ext_ids = for {:target, ex_id} <- Map.keys(targets), do: ex_id

      from(t in Target, where: t.campaign_id == ^campaign_id and not t.external_id in ^ext_ids)
      |> repo.all()
      |> Enum.map(&Target.deleteset/1)
      |> Enum.reduce_while({:ok, 0}, fn tar, {:ok, deleted_count} ->
        case repo.delete(tar) do
          {:ok, _deleted } -> {:cont, {:ok, deleted_count + 1}}
          {:error, errors} = e -> {:halt, e}
        end
       end)
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

  @doc """
  Upserts targets given in `targets` list of attributes, for `campaign_id`

  For each target calls Target.upsert()
  """
  defp upsert_all(multi, targets, campaign_id) do

    targets
    |> Enum.map(&Map.put(&1, :campaign_id, campaign_id))
    |> Target.upsert()
    |> Enum.reduce(multi, fn chset, multi ->
      Multi.insert_or_update(multi, {:target, get_field(chset, :external_id)}, chset)
    end)
  end
end
