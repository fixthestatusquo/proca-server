defmodule ProcaWeb.Schema.OrgTypes do
  @moduledoc """
  API for org entities
  """
  
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Schema.Authenticated

  object :org_queries do
    @desc "Organization api (authenticated)"
    field :org, :org do
      middleware Authenticated

      @desc "Name of organisation"
      arg(:name, non_null(:string))

      resolve(&Resolvers.Org.get_by_name/3)
    end
  end


  object :org do
    @desc "Organization id"
    field :id, :integer

    @desc "Organisation short name"
    field :name, :string

    @desc "Organisation title (human readable name)"
    field :title, :string

    @desc "List campaigns this org is leader or partner of"
    field :campaigns, list_of(:campaign) do
      resolve &Resolvers.Org.campaigns/3
    end

    @desc "List action pages this org has"
    field :action_pages, list_of(:action_page) do
      resolve &Resolvers.Org.action_pages/3
    end

    @desc "Get campaign this org is leader or partner of by id"
    field :campaign, :campaign do
      arg :id, :integer
      resolve &Resolvers.Org.campaign_by_id/3
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

  object :public_org do
    @desc "Organisation short name"
    field :name, :string

    @desc "Organisation title (human readable name)"
    field :title, :string
  end


  object :signature_list do
    @desc "Public key of sender (proca app), in Base64url encoding (RFC 4648 5.)"
    field :public_key, :string
    @desc "List of returned signatures"
    field :list, list_of(:signature)
  end


  object :signature do
    @desc "Signature id"
    field :id, :integer
    @desc "DateTime of signature (UTC)"
    field :created, :datetime
    @desc "Encryption nonce in Base64url"
    field :nonce, :string
    @desc "Encrypted contact data in Base64url"
    field :contact, :string
    @desc "Campaign id"
    field :campaign_id, :integer
    @desc "Action page id"
    field :action_page_id, :integer
    @desc "Opt in given when adding sig"
    field :opt_in, :boolean
  end
end
