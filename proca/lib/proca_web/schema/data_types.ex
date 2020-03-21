defmodule ProcaWeb.Schema.DataTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers

  @desc "Campaign statistics"
  object :campaign_stats do
    @desc "Signature count (naive at the moment)"
    field :signature_count, :integer
  end

  object :campaign do
    field :id, :id
    @desc "Internal name of the campaign"
    field :name, :string
    @desc "Full, official name of the campaign"
    field :title, :string

    @desc "Campaign statistics"
    field :stats, :campaign_stats do
      resolve &Resolvers.Campaign.stats/3
    end
  end

  object :action_page do
    field :id, :id
    @desc "Locale for the widget, in i18n format"
    field :locale, :string
    @desc "Url where the widget is hosted"
    field :url, :string
    @desc "Campaign this widget belongs to"
    field :campaign, :campaign do
      resolve &Resolvers.ActionPage.campaign/3
    end
  end
end
