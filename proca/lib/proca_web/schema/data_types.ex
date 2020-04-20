defmodule ProcaWeb.Schema.DataTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers

  scalar :datetime do
    parse fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, datetime, _} -> {:ok, datetime}
        _ -> :error
      end
    end

    serialize fn datetime ->
      DateTime.from_naive!(datetime, "Etc/UTC")
      |> DateTime.to_iso8601()
    end
  end

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

    field :org, :public_org
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
    field :org, :public_org
  end

  object :org do
    @desc "Organization id"
    field :id, :integer

    @desc "List campaigns this org is running (owns or has action page)"
    field :campaigns, list_of(:campaign) do
      resolve &Resolvers.Org.campaigns/3
    end

    @desc "List action pages this org has"
    field :action_pages, list_of(:action_page) do
      resolve &Resolvers.Org.action_pages/3
    end

    @desc "Get campaign this org is running by id"
    field :campaign, :campaign do
      arg :id, :integer
      resolve &Resolvers.Org.campaign/3
    end

    @desc "Get signatures this org has collected.
Provide campaign_id to only get signatures for a campaign

"
    field :signatures, :signature_list do
      @desc "return only signatures for campaign id"
      arg :campaign_id, :integer
      @desc "return only signatures with id starting from this argument (inclusive)"
      arg :start, :integer
      @desc "return only signatures created at date time from this argument (inclusive)"
      arg :after, :datetime
      @desc "Limit the number of returned signatures"
      arg :limit, :integer

      resolve &Resolvers.Org.signatures/3
    end
  end

  object :signature_list do
    @desc "Public key of sender (proca app), in Base64"
    field :public_key, :string
    @desc "List of returned signatures"
    field :list, list_of(:signature)
  end

  object :signature do
    @desc "Signature id"
    field :id, :integer
    @desc "DateTime of signature (UTC)"
    field :created, :datetime
    @desc "Encryption nonce in Base64"
    field :nonce, :string
    @desc "Encrypted contact data in Base64"
    field :contact, :string
    @desc "Campaign id"
    field :campaign_id, :integer
    @desc "Action page id"
    field :action_page_id, :integer
    @desc "Opt in given when adding sig"
    field :opt_in, :boolean
  end

  object :public_org do
    field :title, :string
  end
end
