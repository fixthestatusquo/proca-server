defmodule ProcaWeb.Schema.CampaignTypes do
  @moduledoc """
  API for campaign and action page entities
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers.Authorized
  alias ProcaWeb.Resolvers

  object :campaign_queries do
    @desc "Get a list of campains"
    field :campaigns, list_of(:campaign) do
      @desc "Filter campaigns by title using LIKE format (% means any sequence of characters)"
      arg(:title, :string)

      @desc "Filter campaigns by name (exact match). If found, returns list of 1 campaign, otherwise an empty list"
      arg(:name, :string)

      @desc "Filter campaigns by id. If found, returns list of 1 campaign, otherwise an empty list"
      resolve(&Resolvers.Campaign.list/3)
    end

    @desc "Get action page"
    field :action_page, :public_action_page do
      @desc "Get action page by id."
      arg(:id, :integer)
      @desc "Get action page by name the widget is displayed on"
      arg(:name, :string)
      @desc "Get action page by url the widget is displayed on (DEPRECATED, use name)"
      arg(:url, :string)

      resolve(&Resolvers.ActionPage.find/3)
    end
  end

  object :campaign_mutations do
    @desc """
    Upserts a campaign.

    Creates or appends campaign and it's action pages. In case of append, it
    will change the campaign with the matching name, and action pages with
    matching names. It will create new action pages if you pass new names. No
    Action Pages will be removed (principle of not removing signature data).
    """
    field :upsert_campaign, type: :campaign do
      middleware(Authorized)

      @desc "Org name"
      arg(:org_name, non_null(:string))

      @desc "Campaign unchanging identifier"
      arg(:name, non_null(:string))

      @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
      arg(:external_id, :integer)

      @desc "Campaign human readable title"
      arg(:title, :string)

      @desc "Custom config as stringified JSON map"
      arg(:config, :json)

      @desc "Action pages of this campaign"
      arg(:action_pages, non_null(list_of(:action_page_input)))

      resolve(&Resolvers.Campaign.upsert/3)
    end

    # XXX deprecated. 
    @desc """
    Deprecated, use upsert_campaign.
    """
    field :declare_campaign, type: :campaign do
      middleware(Authorized)

      @desc "Org name"
      arg(:org_name, non_null(:string))

      @desc "Campaign unchanging identifier"
      arg(:name, non_null(:string))

      @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
      arg(:external_id, :integer)

      @desc "Campaign human readable title"
      arg(:title, non_null(:string))

      @desc "Action pages of this campaign"
      arg(:action_pages, non_null(list_of(:action_page_input_legacy_url)))

      resolve(&Resolvers.Campaign.upsert/3)
    end

    @desc """
    Update an Action Page
    """
    field :update_action_page, type: :action_page do
      middleware(Authorized)

      # XXX Copy from action_page_input and find/replace field->arg. GraphQL is silly here
      @desc """
      Action Page id
      """
      arg(:id, non_null(:integer))

      @desc """
      Unique NAME identifying ActionPage.

      Does not have to exist, must be unique. Can be a 'technical' identifier
      scoped to particular organization, so it does not have to change when the
      slugs/urls change (eg. https://some.org/1234). However, frontent Widget can
      ask for ActionPage by it's current location.href, in which case it is useful
      to make this url match the real idwget location.
      """
      arg(:name, :string)

      @desc "2-letter, lowercase, code of ActionPage language"
      arg(:locale, :string)

      @desc "A reference to thank you email template of this ActionPage"
      arg(:thank_you_template_ref, :string)

      @desc """
      Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. 
      """
      arg(:extra_supporters, :integer)

      @desc """
      List of steps in the journey (deprecated, pass in config)
      """
      arg(:journey, list_of(non_null(:string)))

      @desc """
      JSON string containing Action Page config
      """
      arg(:config, :string)

      resolve(&Resolvers.ActionPage.update/3)
    end
  end

  object :campaign do
    field :id, :integer
    @desc "Internal name of the campaign"
    field :name, :string
    @desc "External ID (if set)"
    field :external_id, :integer
    @desc "Full, official name of the campaign"
    field :title, :string
    @desc "Custom config map"
    field :config, :json

    @desc "Campaign statistics"
    field :stats, :campaign_stats do
      resolve(&Resolvers.Campaign.stats/3)
    end

    @desc "Fetch public actions"
    field :actions, :public_actions_result do
      @desc "Return actions of this action type"
      arg(:action_type, non_null(:string))
      @desc "Limit the number of returned actions, default is 10, max is 100)"
      arg(:limit, :integer)
      resolve(&Resolvers.ActionQuery.list_by_action_type/3)
    end

    field :org, :public_org
  end

  object :action_page do
    field :id, :integer
    @desc "Locale for the widget, in i18n format"
    field :locale, :string
    @desc "Name where the widget is hosted"
    field :name, :string
    @desc "Reference to thank you email templated of this Action Page"
    field :thank_you_template_ref, :string
    @desc "List of steps in journey"
    field :journey, list_of(non_null(:string))
    @desc "Config JSON of this action page"
    field :config, :string
    @desc "Extra supporters (added to supporters count)"
    field :extra_supporters, :integer
    @desc "Campaign this widget belongs to"
    field :campaign, :campaign do
      resolve(&Resolvers.ActionPage.campaign/3)
    end

    field :org, :public_org
  end

  object :public_action_page do
    field :id, :integer
    @desc "Locale for the widget, in i18n format"
    field :locale, :string
    @desc "Name where the widget is hosted"
    field :name, :string
    @desc "Reference to thank you email templated of this Action Page"
    field :thank_you_template_ref, :string
    @desc "List of steps in journey"
    field :journey, list_of(non_null(:string))
    @desc "Config JSON of this action page"
    field :config, :string
    @desc "Campaign this widget belongs to"
    field :campaign, :campaign do
      resolve(&Resolvers.ActionPage.campaign/3)
    end

    field :org, :public_org
  end

  @desc "ActionPage declaration"
  input_object :action_page_input do
    @desc """
    Action Page id
    """
    field :id, :integer

    @desc """
    Unique NAME identifying ActionPage.

    Does not have to exist, must be unique. Can be a 'technical' identifier
    scoped to particular organization, so it does not have to change when the
    slugs/names change (eg. some.org/1234). However, frontent Widget can
    ask for ActionPage by it's current location.href (but without https://), in which case it is useful
    to make this url match the real widget location. 
    """
    field :name, :string

    @desc "2-letter, lowercase, code of ActionPage language"
    field :locale, :string

    @desc "A reference to thank you email template of this ActionPage"
    field :thank_you_template_ref, :string

    @desc """
    Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. 
    """
    field :extra_supporters, :integer

    @desc """
    List of steps in the journey
    """
    field :journey, list_of(non_null(:string))

    @desc """
    JSON string containing Action Page config
    """
    field :config, :string
  end

  @desc "ActionPage declaration (using the legacy url attribute)"
  input_object :action_page_input_legacy_url do
    field :id, :integer
    field :url, :string
    field :locale, :string
    field :thank_you_template_ref, :string
    field :extra_supporters, :integer
    field :journey, list_of(non_null(:string))
    field :config, :string
  end

  # public counters
  @desc "Campaign statistics"
  object :campaign_stats do
    @desc "Signature count (naive at the moment)"
    field :supporter_count, :integer

    @desc "Action counts for selected action types"
    field :action_count, list_of(non_null(:action_type_count))
  end

  @desc "Count of actions for particular action type"
  object :action_type_count do
    @desc "action type"
    field :action_type, non_null(:string)

    @desc "count of actions of action type"
    field :count, non_null(:integer)
  end

  object :action_custom_fields do
    field :action_id, non_null(:integer)
    field :action_type, non_null(:string)
    field :inserted_at, non_null(:datetime)
    field :fields, list_of(non_null(:custom_field))
  end

  @desc "Result of actions query"
  object :public_actions_result do
    field :field_keys, list_of(non_null(:string))
    field :list, list_of(:action_custom_fields)
  end
end
