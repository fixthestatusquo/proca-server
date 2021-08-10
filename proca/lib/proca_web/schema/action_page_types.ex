defmodule ProcaWeb.Schema.ActionPageTypes do
  @moduledoc """
  API for campaign and action page entities
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers.Authorized
  alias ProcaWeb.Resolvers

  object :action_page_queries do
    @desc "Get action page"
    field :action_page, non_null(:action_page) do
      @desc "Get action page by id."
      arg(:id, :integer)
      @desc "Get action page by name the widget is displayed on"
      arg(:name, :string)

      @desc "Get action page by url the widget is displayed on (DEPRECATED, use name)"
      arg(:url, :string)

      resolve(&Resolvers.ActionPage.find/3)
    end
  end


  interface :action_page do 
    field :id, non_null(:integer)
    @desc "Locale for the widget, in i18n format"
    field :locale, non_null(:string)
    @desc "Name where the widget is hosted"
    field :name, non_null(:string)
    @desc "Reference to thank you email templated of this Action Page"
    field :thank_you_template_ref, :string
    @desc "Is live?"
    field :live, non_null(:boolean)
    @desc "List of steps in journey"
    field :journey, non_null(list_of(non_null(:string)))
    @desc "Config JSON of this action page"
    field :config, non_null(:json)
    @desc "Campaign this action page belongs to."
    field :campaign, non_null(:campaign) do
      resolve(&Resolvers.ActionPage.campaign/3)
    end
    @desc "Org the action page belongs to"
    field :org, non_null(:org) do
      resolve(&Resolvers.ActionPage.org/3)
    end

    resolve_type fn 
      %{org_id: org_id}, %{context: %{staffer: %{org_id: org_id}}} -> :private_action_page
      page, %{context: %{staffer: %{org_id: staffer_org_id}}} ->
        if Proca.Repo.preload(page, [:campaign]).campaign.org_id == staffer_org_id do
          :private_action_page
        else
          :public_action_page
        end
      _, _ -> :public_action_page
    end
  end

  object :private_action_page do
    interface :action_page
    import_fields :action_page

    field :extra_supporters, non_null(:integer)
    @desc "Action page collects also opt-out actions"
    field :delivery, non_null(:boolean)

    @desc "Location of the widget as last seen in HTTP REFERER header"
    field :location, :string do 
      resolve fn page, _, _ -> 
        {:ok, Proca.ActionPage.Status.get_last_location(page.id)}
      end
    end

    @desc "Status of action page"
    field :status, :action_page_status do 
      resolve fn page, _, _ -> 
        case Proca.ActionPage.Status.get_last_at(page.id) do 
          nil -> {:ok, :standby}
          seen_at -> 
            now = NaiveDateTime.utc_now()
            if NaiveDateTime.diff(now, seen_at, :second) < Date.days_in_month(now) * 86_400  do 
              {:ok, :active}
            else 
              {:ok, :stalled}
            end

        end
      end
    end
  end

  object :public_action_page do
    interface :action_page 
    import_fields :action_page
  end


  object :action_page_mutations do
    @desc """
    Update an Action Page
    """
    field :update_action_page, type: non_null(:action_page) do
      middleware Authorized,
        access: [:action_page, by: [:id]],
        can?: [:manage_action_pages]

      # XXX Copy from action_page_input and find/replace field->arg. GraphQL is silly here
      @desc """
      Action Page id
      """
      arg :id, non_null(:integer)
      arg :input, non_null(:action_page_input)

      resolve(&Resolvers.ActionPage.update/3)
    end

    @desc """
    Adds a new Action Page based on another Action Page. Intended to be used to
    create a partner action page based off lead's one. Copies: campaign, locale, journey, config, delivery flag
    """
    field :copy_action_page, type: non_null(:action_page) do
      middleware Authorized,
        access: [:org, by: [name: :org_name]],
        can?: [:manage_action_pages]

      @desc "Org owner of new Action Page"
      arg :org_name, non_null(:string)

      @desc "New Action Page name"
      arg :name, non_null(:string)

      @desc "Name of Action Page this one is cloned from"
      arg :from_name, non_null(:string)

      resolve(&Resolvers.ActionPage.copy_from/3)
    end

    @desc """
    Adds a new Action Page based on latest Action Page from campaign. Intended to be used to
    create a partner action page based off lead's one. Copies: campaign, locale, journey, config, delivery flag
    """
    field :copy_campaign_action_page, type: non_null(:action_page) do
      middleware Authorized,
        access: [:org, by: [name: :org_name]],
        can?: [:manage_action_pages]

      @desc "Org owner of new Action Page"
      arg :org_name, non_null(:string)

      @desc "New Action Page name"
      arg :name, non_null(:string)

      @desc "Name of Campaign from which the page is copied"
      arg :from_campaign_name, non_null(:string)

      resolve(&Resolvers.ActionPage.copy_from_campaign/3)
    end

    field :add_action_page, type: non_null(:action_page) do 
      middleware Authorized,
        access: [:org, by: [name: :org_name]],
        can?: [:manage_action_pages]

      @desc "Org owner of new Action Page"
      arg :org_name, non_null(:string)

      @desc "New Action Page name"
      arg :name, non_null(:string)

      @desc "Action Page locale"
      arg :locale, non_null(:string)

      @desc "Name of campaign where page is created"
      arg :campaign_name, non_null(:string)

      resolve(&Resolvers.ActionPage.add_action_page/3)
    end

    field :launch_action_page, type: non_null(:launch_action_page_result) do
      middleware Authorized, access: [:action_page, by: [:name]]

      arg :name, non_null(:string) 

      @desc "Optional message for approver"
      arg :message, :string

      resolve &ProcaWeb.Resolvers.ActionPage.launch_page/3
    end
  end


  @desc "ActionPage input"
  input_object :action_page_input do
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
    field :config, :json
  end



  input_object :select_action_page do
    field :campaign_id, :integer
  end
end
