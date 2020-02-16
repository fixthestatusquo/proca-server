defmodule ProcaWeb.Schema do
  use Absinthe.Schema

  import_types ProcaWeb.Schema.DataTypes

  query do
    @desc "Get a list of campains"
    field :campaigns, list_of(:campaign) do
      resolve fn _p, _a, _r ->
        cl = Proca.Campaign |> Ecto.Query.first |> Proca.Repo.all
        {:ok, cl}
      end
    end
  end

end
