defmodule ProcaWeb.Schema.DataTypes do
  use Absinthe.Schema.Notation

  object :campaign do
    field :id, :id
    field :name, :string
    field :title, :string
  end

  object :action_page do
    field :id, :id
    field :locale, :string
    field :url, :string
    field :campaign, :campaign
  end

end
