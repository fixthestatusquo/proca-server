defmodule ProcaWeb.Resolvers.Target do
  alias Ecto.Multi
  alias Proca.Target
  alias ProcaWeb.Helper

  import Ecto.Query
  alias Proca.Repo

  def upsert_targets(_p, params = %{targets: targets, campaign_id: campaign_id}, _) do
    result = Multi.new
    |> upsert(targets, campaign_id)
    |> Proca.Repo.transaction

    case result do
      {:ok, targets} -> {:ok, Map.values(targets)}
      {:error, error} -> {:error, Helper.format_errors(error)}
    end
  end

  def list(_, %{campaign_id: campaign_id}, _) do
    targets = Target
    |> where(campaign_id: ^campaign_id)
    |> preload(:emails)
    |> Repo.all()

    {:ok, targets}
  end

  defp upsert(multi, targets, campaign_id) do
    Enum.reduce(targets, multi, fn target, multi ->
      target = Map.put(target, :campaign_id, campaign_id)
      Multi.insert(multi, {:target, target.external_id}, upsert_target(target), on_conflict: :replace_all, conflict_target: :external_id, returning: true)
    end)
  end

  defp upsert_target(target) do
    emails = Enum.map(target.emails, fn email -> struct(Proca.TargetEmail, email) end)

    Target.upsert(target, emails)
  end
end
