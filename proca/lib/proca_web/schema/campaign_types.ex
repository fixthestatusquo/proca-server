defmodule ProcaWeb.Schema.CampaignTypes do
  @moduledoc """
  API for campaign and action page entities
  """

  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation
  alias ProcaWeb.Resolvers
  alias Proca.Auth

  object :campaign_queries do
    # XXX this works as search function
    # XXX maybe rename this to public? We cannot easily determine auth context for each
    # campaign in the list.
    # XXX add: by org name
    @desc """
    Returns a public list of campaigns, filtered by title. Can be used to implement a campaign search box on a website.
    """
    field :campaigns, non_null(list_of(non_null(:campaign))) do
      @desc "Filter campaigns by title using LIKE format (% means any sequence of characters)"
      arg(:title, :string)

      # XXX remove
      @desc "DEPRECATED: use campaign() to get one campaign. Filter campaigns by name (exact match). If found, returns list of 1 campaign, otherwise an empty list"
      arg(:name, :string)

      # XXX remove
      @desc "DEPRECATED: use campaign() to get one campaign. Select by id, Returns list of 1 result"
      arg(:id, :integer)

      # XXX by partnership perhaps?
      # by org_name

      # @desc "Campaigns accesible to current user (via group or org)"
      # arg(:mine, :boolean)

      resolve(&Resolvers.Campaign.list/3)
    end

    @desc """
    Get one campaign. If you have access to the campaign, as lead or
    partner, you will get a private view of the campaign, otherwise, a public
    view.
    """
    field :campaign, :campaign do
      @desc "Get by id"
      arg(:id, :integer)
      @desc "Get by name"
      arg(:name, :string)
      #     arg(:external_id, :integer)

      load(:campaign, by: [:id, :name], preload: [:org, :targets])
      determine_auth(for: :campaign)
      resolve(&Resolvers.Campaign.return_from_context/3)
    end
  end

  interface :campaign do
    @desc "Campaign id"
    field :id, non_null(:integer)
    @desc "External ID (if set)"
    field :external_id, :integer

    @desc "Internal name of the campaign"
    field :name, non_null(:string)
    @desc "Full, official name of the campaign"
    field :title, non_null(:string)
    @desc "Current status of the campaign"
    field :status, non_null(:campaign_status)
    @desc "Schema for contact personal information"
    field :contact_schema, non_null(:contact_schema)
    @desc "Custom config map"
    field :config, non_null(:json)

    @desc "Statistics"
    field :stats, non_null(:campaign_stats) do
      resolve(&Resolvers.Campaign.stats/3)
    end

    @desc "Lead org"
    field :org, non_null(:org), do: load_assoc()

    @desc """
    Fetch public actions. Can be used to display recent comments for example.

    To allow-list action fields to be public, `campaign.public_actions` must be set to a list of strings in form
    action_type:custom_field_name, eg: `["signature:comment"]`. XXX this cannot be set in API, you need to set in backend.
    """
    field :actions, non_null(:public_actions_result) do
      @desc "Specify action type to return"
      arg(:action_type, non_null(:string))
      @desc "Limit the number of returned actions, default is 10, max is 100)"
      arg(:limit, non_null(:integer), default_value: 10)
      resolve(&Resolvers.ActionQuery.list_by_action_type/3)
    end

    @desc "List MTT targets of this campaign"
    field :targets, list_of(:target) do
      resolve(&Resolvers.Campaign.targets/3)
    end

    resolve_type(fn
      %{org_id: org_id}, %{context: %{auth: %Auth{staffer: %{org_id: org_id}}}} ->
        :private_campaign

      _org, %{context: %{auth: auth}} ->
        if Proca.Permission.can?(auth, [:instance_owner]) do
          :private_campaign
        else
          :public_campaign
        end

      _, _ ->
        :public_campaign
    end)
  end

  object :public_campaign do
    interface(:campaign)
    import_fields(:campaign)
  end

  object :private_campaign do
    interface(:campaign)
    import_fields(:campaign)

    @desc "Campaign onwer collects opt-out actions for delivery even if campaign partner is delivering"
    field :force_delivery, non_null(:boolean)

    @desc "Action Pages of this campaign that are accessible to current user"
    field :action_pages, non_null(list_of(non_null(:private_action_page))) do
      resolve(&Resolvers.Campaign.action_pages_for_auth/3)
    end

    @desc "List of partnerships and requests to join partnership"
    field :partnerships, list_of(non_null(:partnership)) do
      resolve(&Resolvers.Campaign.partnerships/3)
    end

    @desc "MTT configuration"
    field :mtt, :campaign_mtt, do: load_assoc()
  end

  # Partnership
  object :partnership do
    @desc """
    Partner org
    """
    field :org, non_null(:org)

    @desc """
    Partner's pages that are part of this campaign (can be more, eg: multiple languages)
    """
    field :action_pages, non_null(list_of(non_null(:action_page))) do
      resolve(&Resolvers.Campaign.partnership_action_pages/3)
    end

    @desc """
    Join/Launch requests of this partner
    """
    field :launch_requests, non_null(list_of(non_null(:confirm))) do
      resolve(&Resolvers.Campaign.partnership_launch_requests/3)
    end

    @desc """
    The partner staffers who initiated a request
    """
    field :launch_requesters, non_null(list_of(non_null(:user))) do
      resolve(&Resolvers.Campaign.partnership_requesters/3)
    end
  end

  object :launch_action_page_result do
    field :status, non_null(:status)
  end

  object :campaign_mutations do
    @desc """
    Upserts a campaign.

    Creates or appends campaign and it's action pages. In case of append, it
    will change the campaign with the matching name, and action pages with
    matching names. It will create new action pages if you pass new names. No
    Action Pages will be removed (principle of not removing signature data).
    """
    field :upsert_campaign, type: non_null(:campaign) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:manage_campaigns])

      @desc "Org name"
      arg(:org_name, non_null(:string))

      @desc "Campaign content to be upserted"
      arg(:input, non_null(:campaign_input))

      resolve(&Resolvers.Campaign.upsert/3)
    end

    @desc """
    Updates an existing campaign.
    """
    field :update_campaign, type: non_null(:campaign) do
      @desc "Id of campaign to update"
      arg(:id, :integer)
      @desc "Name of campaign to update (alterantive to id)"
      arg(:name, :string)
      # arg(:external_id, :integer)

      @desc "Campaign content to be updated"
      arg(:input, non_null(:campaign_input))

      load(:campaign, by: [:id, :name], preload: [:mtt])
      determine_auth(for: :campaign)
      allow([:manage_campaigns, :change_campaign_settings])

      resolve(&Resolvers.Campaign.update/3)
    end

    @desc """
    Add a new campaign
    """
    field :add_campaign, type: non_null(:campaign) do
      @desc "Org that is lead of this campaign"
      arg(:org_name, non_null(:string))

      @desc "Campaign content to be added"
      arg(:input, non_null(:campaign_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:manage_campaigns])

      resolve(&Resolvers.Campaign.add/3)
    end

    @desc """
    Delete a campaign.
    Deletion will be blocked if there are action pages with personal data (we never remove personal data unless via GDPR).
    """
    field :delete_campaign, type: non_null(:status) do
      @desc "by id"
      arg(:id, :integer)
      @desc "by name"
      arg(:name, :string)
      @desc "by external_id"
      arg(:external_id, :integer)

      load(:campaign, by: [:id, :name, :external_id])
      determine_auth(for: :campaign)
      allow([:manage_campaigns])

      resolve(&Resolvers.Campaign.delete/3)
    end
  end

  @desc "Campaign content changed in mutations"
  input_object :campaign_input do
    @desc "Campaign short name"
    field(:name, :string)

    @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
    field(:external_id, :integer)

    @desc "Campaign human readable title"
    field(:title, :string)

    @desc "Schema for contact personal information"
    field(:contact_schema, :contact_schema)

    @desc "Current status of the campaign"
    field(:status, :campaign_status)

    @desc "Custom config as stringified JSON map"
    field(:config, :json)

    @desc "Action pages of this campaign"
    field(:action_pages, list_of(non_null(:action_page_input)))

    @desc "MTT configuration"
    field(:mtt, :campaign_mtt_input)
  end

  object :campaign_mtt do
    @desc "This is first day and start hour of the campaign. Note, every day of the campaign the start hour will be same."
    field :start_at, non_null(:datetime)

    @desc "This is last day and end hour of the campaign. Note, every day of the campaign the end hour will be same."
    field :end_at, non_null(:datetime)

    @desc """
    If email templates are used to create MTT, use this template (works like thank you email templates).
    Otherwise, the raw text that is send with MTT action will make a plain text email.
    """
    field :message_template, :string

    @desc """
    A test target email (yourself) where test mtt actions will be sent (instead to real targets)
    """
    field :test_email, :string
  end

  input_object :campaign_mtt_input do
    @desc "This is first day and start hour of the campaign. Note, every day of the campaign the start hour will be same."
    field :start_at, :datetime

    @desc "This is last day and end hour of the campaign. Note, every day of the campaign the end hour will be same."
    field :end_at, :datetime

    @desc """
    If email templates are used to create MTT, use this template (works like thank you email templates).
    Otherwise, the raw text that is send with MTT action will make a plain text email.
    """
    field :message_template, :string

    @desc """
    A test target email (yourself) where test mtt actions will be sent (instead to real targets)
    """
    field :test_email, :string
  end

  # public counters
  @desc "Campaign statistics"
  object :campaign_stats do
    @desc "Unique action tagers count"
    field :supporter_count, non_null(:integer)

    @desc "Unique action takers by area"
    field :supporter_count_by_area, non_null(list_of(non_null(:area_count)))

    @desc "Unique action takers by org"
    field :supporter_count_by_org, non_null(list_of(non_null(:org_count))) do
      resolve(&Resolvers.Campaign.org_stats/3)
    end

    @desc "Unique supporter count not including the ones collected by org_name"
    field :supporter_count_by_others, non_null(:integer) do
      @desc "Org name to exclude from counting supporters"
      arg(:org_name, non_null(:string))
      resolve(&Resolvers.Campaign.org_stats_others/3)
    end

    @desc "Action counts per action types (with duplicates)"
    field :action_count, non_null(list_of(non_null(:action_type_count)))
  end

  @desc "Count of actions for particular action type"
  object :action_type_count do
    @desc "action type"
    field :action_type, non_null(:string)

    @desc "count of actions of action type"
    field :count, non_null(:integer)
  end

  @desc "Count of actions for particular action type"
  object :area_count do
    @desc "area"
    field :area, non_null(:string)

    @desc "count of supporters in this area"
    field :count, non_null(:integer)
  end

  @desc "Count of supporters for particular org"
  object :org_count do
    @desc "org"
    field :org, non_null(:org)

    @desc "count of supporters registered by org"
    field :count, non_null(:integer)
  end

  object :action_custom_fields do
    @desc "id of action"
    field :action_id, non_null(:integer)
    @desc "type of action"
    field :action_type, non_null(:string)
    @desc "creation timestamp"
    field :inserted_at, non_null(:naive_datetime)
    @desc "area of supporter that did the action"
    field :area, :string
    @desc "custom fields as stringified json"
    field :custom_fields, non_null(:json)

    field :fields, non_null(list_of(non_null(:custom_field))), deprecate: "use custom_fields" do
      resolve(fn action, _p, _c ->
        {:ok, Proca.Field.map_to_list(action.custom_fields)}
      end)
    end
  end

  @desc "Result of actions query"
  object :public_actions_result do
    @desc "Custom field keys which are public"
    field :field_keys, list_of(non_null(:string))
    @desc "List of actions custom fields"
    field :list, list_of(:action_custom_fields)
  end

  input_object :select_campaign do
    field :title_like, :string
    field :org_name, :string
  end
end
