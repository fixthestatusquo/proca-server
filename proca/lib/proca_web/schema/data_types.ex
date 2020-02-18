defmodule ProcaWeb.Schema.DataTypes do
  use Absinthe.Schema.Notation

  object :campaign do
    field :id, :id
    @desc "Internal name of the campaign"
    field :name, :string
    @desc "Full, official name of the campaign"
    field :title, :string
  end

  object :action_page do
    field :id, :id
    @desc "Locale for the widget, in i18n format"
    field :locale, :string
    @desc "Url where the widget is hosted"
    field :url, :string
    @desc "Campaign this widget belongs to"
    field :campaign, :campaign
  end
end
