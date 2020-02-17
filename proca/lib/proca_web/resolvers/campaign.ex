defmodule ProcaWeb.Resolvers.Campaign do
  import Ecto.Query


  def list(_, %{id: id}, _) do
    cl = Proca.Repo.all from x in Proca.Campaign, where: x.id == ^id
    {:ok, cl}
  end

  def list(_, %{name: name}, _) do
    cl = Proca.Repo.all from x in Proca.Campaign, where: x.name == ^name
    {:ok, cl}
  end

  def list(_, %{title: title}, _) do
    cl = Proca.Repo.all from x in Proca.Campaign, where: like(x.title, ^title)
    {:ok, cl}
  end

  def list(_, _, _) do
    cl = Proca.Repo.all Proca.Campaign
    {:ok, cl}
  end
end
