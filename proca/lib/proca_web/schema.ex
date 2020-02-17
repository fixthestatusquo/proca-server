defmodule ProcaWeb.Schema do
  use Absinthe.Schema
  alias ProcaWeb.Resolvers

  import_types ProcaWeb.Schema.DataTypes

  query do
    @desc "Get a list of campains"
    field :campaigns, list_of(:campaign) do
      arg :title, :string
      arg :name, :string
      arg :id, :integer
      resolve &Resolvers.Campaign.list/3
    end
  end
end
