defmodule ProcaWeb.Resolvers.ActionPage do
  import Ecto.Query

  defp find_criteria(query, %{id: id}) do
    query |> where([x], x.id == ^id)
  end

  defp find_criteria(query, %{url: url}) do
    query |> where([x], x.url == ^url)
  end

  def find(_, args, _) do
    query = (from p in Proca.ActionPage, preload: [:campaign])
    |> find_criteria(args)

    case Proca.Repo.one query do
      nil -> {:error, "Not found"}
      ap -> {:ok, ap}
    end
  end
end
