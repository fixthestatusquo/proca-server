defmodule ProcaWeb.Resolvers.ActionPage do
  import Ecto.Query
  alias Proca.Repo

  defp by_id(query, id) do
    query |> where([x], x.id == ^id)
  end

  defp by_url(query,  url) do
    query |> where([x], x.url == ^url)
  end

  defp find_one(criteria) do
    query = (from p in Proca.ActionPage, preload: [[campaign: :org], :org])
    |> criteria.()

    case Proca.Repo.one query do
      nil -> {:error, %{
                 message: "Action page not found",
                 extensions: %{code: "not_found"} } }
      ap -> {:ok, ap}
    end
  end

  def find(_, %{id: id}, _) do
    find_one(& by_id &1, id)
  end

  def find(_, %{url: url}, _) do
    find_one(& by_url &1, url)
  end

  def find(_, %{}, _) do
    {:error, "You must pass either id or url to query for ActionPage"}
  end

  def campaign(ap, %{}, _) do
    {
      :ok,
      Ecto.assoc(ap, :campaign) |> Repo.one
    }
  end
end
