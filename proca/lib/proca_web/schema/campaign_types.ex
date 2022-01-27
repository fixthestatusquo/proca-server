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
    @desc "Get a list of campains"
    field :campaigns, non_null(list_of(non_null(:campaign))) do
      @desc "Filter campaigns by title using LIKE format (% means any sequence of characters)"
      arg(:title, :string)

      # XXX remove
      @desc "DEPRECATED: use campaign(). Filter campaigns by name (exact match). If found, returns list of 1 campaign, otherwise an empty list"
      arg(:name, :string)

      # XXX remove
      @desc "DEPRECATED: use campaign(). Select by id, Returns list of 1 result"
      arg(:id, :integer)

      # XXX by partnership perhaps?
      # by org_name

      # @desc "Campaigns accesible to current user (via group or org)"
      # arg(:mine, :boolean)

      @desc "Filter campaigns by id. If found, returns list of 1 campaign, otherwise an empty list"
      resolve(&Resolvers.Campaign.list/3)
    end

    @desc "Get campaign"
    field :campaign, :campaign do
      arg(:id, :integer)
      arg(:name, :string)
      arg(:external_id, :integer)

      resolve(&Resolvers.Campaign.get/3)
      determine_auth(for: :result)
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
    @desc "Schema for contact personal information"
    field :contact_schema, non_null(:contact_schema)
    @desc "Custom config map"
    field :config, non_null(:json)

    @desc "Campaign statistics"
    field :stats, non_null(:campaign_stats) do
      resolve(&Resolvers.Campaign.stats/3)
    end

    field :org, non_null(:org), do: load_assoc()

    @desc "Fetch public actions"
    field :actions, non_null(:public_actions_result) do
      @desc "Return actions of this action type"
      arg(:action_type, non_null(:string))
      @desc "Limit the number of returned actions, default is 10, max is 100)"
      arg(:limit, non_null(:integer), default_value: 10)
      resolve(&Resolvers.ActionQuery.list_by_action_type/3)
    end

    field :targets, list_of(:target) do
      resolve(&Resolvers.Campaign.targets/3)
    end

    resolve_type(fn
      %{org_id: org_id}, %{context: %{auth: %Auth{staffer: %{org_id: org_id}}}} ->
        :private_campaign

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

    @desc "Campaign onwer collects opt-out actions for delivery even if campaign partner is"
    field :force_delivery, non_null(:boolean)

    @desc "Action Pages of this campaign that are accessible to current user"
    field :action_pages, non_null(list_of(non_null(:private_action_page))) do
      resolve(&Resolvers.Campaign.action_pages_for_auth/3)
    end

    @desc "List of partnerships and requests"
    field :partnerships, list_of(non_null(:partnership)) do
      resolve(&Resolvers.Campaign.partnerships/3)
    end

    @desc "MTT configuration"
    field :mtt, :campaign_mtt, do: load_assoc()
  end

  # Partnership
  object :partnership do
    field :org, non_null(:org)

    field :action_pages, non_null(list_of(non_null(:action_page))) do
      resolve(&Resolvers.Campaign.partnership_action_pages/3)
    end

    field :launch_requests, non_null(list_of(non_null(:confirm))) do
      resolve(&Resolvers.Campaign.partnership_launch_requests/3)
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
      allow([:manage_campaigns])

      @desc "Org name"
      arg(:org_name, non_null(:string))
      arg(:input, non_null(:campaign_input))

      resolve(&Resolvers.Campaign.upsert/3)
    end

    field :update_campaign, type: non_null(:campaign) do
      arg(:id, :integer)
      arg(:name, :string)
      arg(:external_id, :integer)

      arg(:input, non_null(:campaign_input))

      load(:campaign, by: [:id, :name, :external_id], preload: [:mtt])
      determine_auth(for: :campaign)
      allow([:manage_campaigns, :change_campaign_settings])

      resolve(&Resolvers.Campaign.update/3)
    end

    field :add_campaign, type: non_null(:campaign) do
      @desc "Org that is lead of this campaign"
      arg(:org_name, non_null(:string))

      arg(:input, non_null(:campaign_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:manage_campaigns])

      resolve(&Resolvers.Campaign.add/3)
    end

    field :delete_campaign, type: non_null(:status) do
      arg(:id, :integer)
      arg(:name, :string)
      arg(:external_id, :integer)

      load(:campaign, by: [:id, :name, :external_id])
      determine_auth(for: :campaign)
      allow([:manage_campaigns])

      resolve(&Resolvers.Campaign.delete/3)
    end
  end

  @desc "Campaign input"
  input_object :campaign_input do
    @desc "Campaign unchanging identifier"
    field(:name, :string)

    @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
    field(:external_id, :integer)

    @desc "Campaign human readable title"
    field(:title, :string)

    @desc "Schema for contact personal information"
    field(:contact_schema, :contact_schema)

    @desc "Custom config as stringified JSON map"
    field(:config, :json)

    @desc "Action pages of this campaign"
    field(:action_pages, list_of(non_null(:action_page_input)))

    @desc "MTT configuration"
    field(:mtt, :campaign_mtt_input)
  end

  object :campaign_mtt do
    field :start_at, non_null(:datetime)
    field :end_at, non_null(:datetime)
    field :message_template, :string
  end

  input_object :campaign_mtt_input do
    field :start_at, :datetime
    field :end_at, :datetime
    field :message_template, :string
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

    field :supporter_count_by_others, non_null(:integer) do
      arg(:org_name, non_null(:string))
      resolve(&Resolvers.Campaign.org_stats_others/3)
    end

    @desc "Action counts for selected action types"
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
    field :action_id, non_null(:integer)
    field :action_type, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :custom_fields, non_null(:json)

    field :fields, non_null(list_of(non_null(:custom_field))), deprecate: "use custom_fields" do
      resolve(fn action, _p, _c ->
        {:ok, Proca.Field.map_to_list(action.custom_fields)}
      end)
    end
  end

  @desc "Result of actions query"
  object :public_actions_result do
    field :field_keys, list_of(non_null(:string))
    field :list, list_of(:action_custom_fields)
  end

  input_object :select_campaign do
    field :title_like, :string
    field :org_name, :string
  end
end
