defmodule ProcaWeb.Schema do
  use Absinthe.Schema
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Schema.Authenticated

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.InputTypes)

  query do
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
    field :action_page, :action_page do
      @desc "Get action page by id."
      arg(:id, :integer)
      @desc "Get action page by url the widget is displayed on"
      arg(:url, :string)

      resolve(&Resolvers.ActionPage.find/3)
    end

    @desc "Organization api (authenticated)"
    field :org, :org do
      @desc "Name of organisation"
      arg(:name, non_null(:string))

      resolve(&Resolvers.Org.find/3)
    end
  end

  mutation do
    @desc "Adds an action referencing contact data via contactRef"
    field :add_action, type: :contact_reference do
      arg(:action_page_id, non_null(:integer))
      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "Contact reference"
      arg(:contact_ref, :id)

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      resolve(&Resolvers.Action.add_action/3)
    end

    @desc "Adds an action with contact data"
    field :add_action_contact, type: :contact_reference do
      arg(:action_page_id, non_null(:integer))
      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "GDPR communication opt"
      arg(:contact, non_null(:contact_input))
      @desc "Signature action data"
      arg(:privacy, non_null(:consent_input))

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      @desc "Links to previous contact reference"
      arg(:contact_ref, :id)

      resolve(&Resolvers.Action.add_action_contact/3)
    end

    @desc "Link actions with refs to contact with contact reference"
    field :link_actions, type: :contact_reference do
      @desc "Action Page id"
      arg(:action_page_id, non_null(:integer))

      @desc "Contact reference"
      arg(:contact_ref, non_null(:id))

      @desc "Link actions with these references (if unlinked to supporter)"
      arg(:link_refs, list_of(non_null(:string)))

      resolve(&Resolvers.Action.link_actions/3)
    end

    @desc """
    Upserts a campaign.

    Creates or appends campaign and it's action pages. In case of append, it
    will change the campaign with the matching name, and action pages with
    matching urls. It will create new action pages if you pass a new urls. No
    Action Pages will be removed (principle of not removing signature data).
    """
    field :upsert_campaign, type: :campaign do
      @desc "Org name"
      arg(:org_name, non_null(:string))

      @desc "Campaign unchanging identifier"
      arg(:name, non_null(:string))

      @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
      arg(:external_id, :integer)

      @desc "Campaign human readable title"
      arg(:title, non_null(:string))

      @desc "Action pages of this campaign"
      arg(:action_pages, non_null(list_of(:action_page_input)))

      resolve(&Resolvers.Campaign.upsert/3)
    end

    @desc """
    Upserts an Action Page
    """
    field :update_action_page, type: :action_page do
      middleware Authenticated

      # XXX Copy from action_page_input and find/replace filed->arg. GraphQL is silly here
      @desc """
      Action Page id
      """
      arg :id, non_null(:integer)

      @desc """
      Unique URL identifying ActionPage.

      Does not have to exist, must be unique. Can be a 'technical' identifier
      scoped to particular organization, so it does not have to change when the
      slugs/urls change (eg. https://some.org/1234). However, frontent Widget can
      ask for ActionPage by it's current location.href, in which case it is useful
      to make this url match the real idwget location.
      """
      arg :url, :string

      @desc "2-letter, lowercase, code of ActionPage language"
      arg :locale, :string

      @desc "A reference to thank you email template of this ActionPage"
      arg :thank_you_template_ref, :string

      @desc """
      Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. 
      """
      arg :extra_supporters, :integer

      @desc """
      List of steps in the journey
      """
      arg :journey, list_of(non_null(:string))

      @desc """
      JSON string containing Action Page config
      """
      arg :config, :string

      resolve(&Resolvers.ActionPage.update/3)
    end

    # XXX deprecated. 
    @desc """
    Deprecated, use upsert_campaign.
    """
    field :declare_campaign, type: :campaign do
      @desc "Org name"
      arg(:org_name, non_null(:string))

      @desc "Campaign unchanging identifier"
      arg(:name, non_null(:string))

      @desc "Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign"
      arg(:external_id, :integer)

      @desc "Campaign human readable title"
      arg(:title, non_null(:string))

      @desc "Action pages of this campaign"
      arg(:action_pages, non_null(list_of(:action_page_input)))

      resolve(&Resolvers.Campaign.upsert/3)
    end

  end
end
