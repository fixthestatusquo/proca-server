defmodule ProcaWeb.Schema.OrgTypes do
  @moduledoc """
  API for org entities
  """
  
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  object :org_queries do
    @desc "Organization api (authenticated)"
    field :org, :org do
      middleware Authorized

      @desc "Name of organisation"
      arg(:name, non_null(:string))

      resolve(&Resolvers.Org.get_by_name/3)
    end
  end

  object :org_mutations do
    field :update_org, type: :org do
      middleware Authorized

      @desc "Name of organisation, used for lookup, can't be used to change org name"
      arg :name, non_null(:string)

      @desc "Organisation title (human readable name)"
      arg :title, :string

      @desc "Schema for contact personal information"
      arg :contact_schema, :contact_schema

      @desc "Email opt in enabled"
      arg :email_opt_in, :boolean

      @desc "Email opt in template name"
      arg :email_opt_in_template, :string

      resolve(&Resolvers.Org.update_org/3)
    end
  end

  object :org do
    @desc "Organization id"
    field :id, :integer

    @desc "Organisation short name"
    field :name, :string

    @desc "Organisation title (human readable name)"
    field :title, :string

    field :personal_data, non_null(:personal_data) do
      resolve &Resolvers.Org.org_personal_data/3
    end

    field :keys, non_null(list_of(non_null(:key))) do
      resolve &Resolvers.Org.list_keys/3
    end

    # TODO:
    # field :public_keys, non_null(list_of(non_null(:string)))
    # field :users, non_null(list_of(:org_user))
    # field :services, non_null(list_of(:service))

    # field :personal_data, :personal_data
    #  field :contact_schema, :string
    #  field :email_opt_in, :boolean
    #  field :email_opt_in_template, :string

    # field :processing, :processing
    #  field :email_from, :string
    #  field :email_backend, :string
    #  field :template_backend, :string
    #
    #  field :custom_supporter_confirm, :boolean
    #  field :custom_action_confirm, :boolean
    #  field :custom_action_deliver, :boolean
    #
    #  field :sqs_deliver, :boolean


    @desc "List campaigns this org is leader or partner of"
    field :campaigns, list_of(:campaign) do
      resolve &Resolvers.Org.campaigns/3
    end

    @desc "List action pages this org has"
    field :action_pages, list_of(:action_page) do
      resolve &Resolvers.Org.action_pages/3
    end

    @dest "Action Page"
    field :action_page, :action_page do
      arg :id, :integer
      arg :name, :string
      resolve &Resolvers.Org.action_page/3
    end

    @desc "Get campaign this org is leader or partner of by id"
    field :campaign, :campaign do
      arg :id, :integer
      resolve &Resolvers.Org.campaign_by_id/3
    end

    @desc """
    Get signatures this org has collected.
    Provide campaign_id to only get signatures for a campaign
    XXX DEPRECATE AND REMOVE
    """
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

  enum :contact_schema do
    value :basic
    value :popular_initiative
  end

  object :personal_data do
    @desc "Schema for contact personal information"
    field :contact_schema, non_null(:contact_schema)

    @desc "Email opt in enabled"
    field :email_opt_in, non_null(:boolean)

    @desc "Email opt in template name"
    field :email_opt_in_template, :string
  end

  @desc "Encryption or sign key with integer id (database)"
  object :key do
    field :id, non_null(:integer)
    field :public, non_null(:string)
    field :name, :string
    field :expired_at, :datetime
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
