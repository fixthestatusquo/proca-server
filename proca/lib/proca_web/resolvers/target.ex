defmodule ProcaWeb.Resolvers.Target do
  alias Ecto.Multi
  alias Proca.Target
  alias Proca.TargetEmail
  alias ProcaWeb.Helper

  import Ecto.Query
  alias Proca.Repo

  def upsert_targets(_p, %{targets: targets, campaign_id: campaign_id}, _) do
    result =
      Multi.new()
      |> upsert_all(targets, campaign_id)
      |> Proca.Repo.transaction()

    case result do
      {:ok, targets} ->
        {:ok, Map.values(targets)}

      {:error, error} ->
        {:error, Helper.format_errors(error)}
    end
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
