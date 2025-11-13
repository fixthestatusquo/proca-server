defmodule ProcaWeb.Schema.OrgTypes do
  @moduledoc """
  API for org entities
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation
  alias Proca.Auth
  import Proca.Permission, only: [can?: 2]

  object :org_queries do
    @desc "Organization api (authenticated)"
    field :org, non_null(:private_org) do
      @desc "Name of organisation"
      arg(:name, non_null(:string))

      load(:org, by: [:name], preload: [:action_pages, campaigns: :org])
      determine_auth(for: :org)
      allow(:staffer)

      resolve(&Resolvers.Org.return_from_context/3)
    end
  end

  # MAIN TYPE
  interface :org do
    @desc "Organisation short name"
    field :name, non_null(:string)

    @desc "Organisation title (human readable name)"
    field :title, non_null(:string)

    @desc "config"
    field :config, non_null(:json)

    ##
    ## Resolve type second argument:
    ## %{
    ##    parent_type: %Type{identifier: :user_role }
    ##    path: [ %{name: "field"}, 123, ... ]
    ##  }
    ##
    resolve_type(fn
      %{id: org_id}, %{context: %{auth: %Auth{staffer: %{org_id: org_id}}}} ->
        :private_org

      _, %{path: [_org, _idx, _roles, %{name: "currentUser"} | _]} ->
        :private_org

      _, %{context: %{auth: %Auth{} = auth}} ->
        if can?(auth, [:manage_orgs]) do
          :private_org
        else
          :public_org
        end

      _, _ ->
        :public_org
    end)
  end

  object :public_org do
    interface(:org)
    import_fields(:org)
  end

  object :private_org do
    interface(:org)
    import_fields(:org)

    @desc "Organization id"
    field :id, non_null(:integer)

    @desc "Personal data settings for this org"
    field :personal_data, non_null(:personal_data) do
      resolve(&Resolvers.Org.org_personal_data/3)
    end

    @desc "Encryption keys"
    field :keys, non_null(list_of(non_null(:key))) do
      arg(:select, :select_key)
      resolve(&Resolvers.Org.list_keys/3)
    end

    @desc "Get encryption key"
    field :key, non_null(:key) do
      @desc "Parameters to select the key by"
      arg(:select, non_null(:select_key))
      resolve(&Resolvers.Org.get_key/3)
    end

    @desc "Services of this org"
    field :services, non_null(list_of(:service)) do
      @desc "Parameters to select the key by"
      arg(:select, :select_service)
      resolve(&Resolvers.Org.list_services/3)
    end

    @desc "Users of this org"
    field :users, non_null(list_of(:org_user)) do
      resolve(&Resolvers.User.list_org_users/3)
    end

    @desc "Action processing settings for this org"
    field :processing, non_null(:processing) do
      resolve(&Resolvers.Org.org_processing/3)
    end

    # field :templates, non_null(list_of(non_null(:email_template))) do
    #   resolve(&Resolvers.Org.list_templates/3)
    # end

    # field :processing, :processing
    #  field :email_from, :string
    #  field :email_backend, :string
    #
    #  field :custom_supporter_confirm, :boolean
    #  field :custom_action_confirm, :boolean
    #  field :custom_action_deliver, :boolean
    #
    #  field :sqs_deliver, :boolean

    # XXX rethink this API after we add partnerships
    # Campaign should not be hidden under the org, but should be available somehow.
    # Perhaps via partnerships as then we can select by partnership-role
    @desc "List campaigns this org is leader or partner of"
    field :campaigns, non_null(list_of(non_null(:campaign))) do
      arg(:select, :select_campaign)
      resolve(&Resolvers.Campaign.list/3)
    end

    @desc "List action pages this org has"
    field :action_pages, non_null(list_of(non_null(:action_page))) do
      arg(:select, :select_action_page)
      resolve(&Resolvers.Org.action_pages/3)
    end

    @desc "Get one page belonging to this org"
    field :action_page, non_null(:action_page) do
      @desc "Id of page"
      arg(:id, :integer)
      @desc "Name of page"
      arg(:name, :string)

      load(:action_page, by: [:id, :name], preload: [:org, campaign: :org])
      middleware(ProcaWeb.Resolvers.NormalizeError)

      resolve(&Resolvers.Org.action_page/3)
    end

    # XXX remove, campaigns should be accessed directly from root
    @desc "DEPRECATED: use campaign() in API root. Get campaign this org is leader or partner of by id"
    field :campaign, non_null(:campaign) do
      arg(:id, non_null(:integer))
      resolve(&Resolvers.Org.campaign_by_id/3)
    end
  end

  input_object :org_input do
    @desc "Name used to rename"
    field :name, :string

    @desc "Organisation title (human readable name)"
    field :title, :string

    @desc "Schema for contact personal information"
    field :contact_schema, :contact_schema

    # field that are duplicated under personal_data
    @desc "Email opt in enabled"
    field :supporter_confirm, :boolean

    @desc "Email opt in template name"
    field :supporter_confirm_template, :string

    @desc "Only send thank you emails to opt-ins"
    field :doi_thank_you, :boolean

    @desc "Enable reply_to for emails"
    field :reply_enabled, :boolean

    @desc "Config"
    field :config, :json
  end

  object :org_mutations do
    @desc "Add an org. Calling user  will become it's owner."
    field :add_org, type: non_null(:org) do
      @desc "Contet of the org to be added"
      arg(:input, non_null(:org_input))

      allow(:user)
      resolve(&Resolvers.Org.add_org/3)
    end

    @desc "Delete an org"
    field :delete_org, type: non_null(:status) do
      @desc "Name of organisation to be deleted"
      arg(:name, non_null(:string))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:org_owner])

      resolve(&Resolvers.Org.delete_org/3)
    end

    @desc "Update an org"
    field :update_org, type: non_null(:private_org) do
      @desc "Name of organisation, used for lookup, can't be used to change org name"
      arg(:name, non_null(:string))
      @desc "Content of org to be updated"
      arg(:input, non_null(:org_input))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.Org.update_org/3)
    end

    @desc "Update org processing settings"
    field :update_org_processing, type: non_null(:private_org) do
      @desc "Set email backend to"

      @desc "Name of the org (to rename it)"
      arg(:name, non_null(:string))
      @desc "Use a particular owned service type for sending emails"
      arg(:email_backend, :service_name)
      @desc "Envelope FROM email when sending emails"
      arg(:email_from, :string)

      @desc "Is the supporter required to double opt in their action (and associated personal data)?"
      arg(:supporter_confirm, :boolean)
      @desc "The email template name that will be used to send the action DOI request"
      arg(:supporter_confirm_template, :string)

      @desc "Should the thank you email be only send when email consent doi is required (and contain it)"
      arg(:doi_thank_you, :boolean)

      @desc "Should proca put action in a custom queue, so an external service can do this?"
      arg(:custom_supporter_confirm, :boolean)
      @desc "Should proca put action in a custom queue, so an external service can do this?"
      arg(:custom_action_confirm, :boolean)

      @desc "Should proca put action in custom delivery queue, so an external service can sync it?"
      arg(:custom_action_deliver, :boolean)

      @desc "Should proca put events in custom delivery queue, so an external service can sync it?"
      arg(:custom_event_deliver, :boolean)

      @desc "Use a particular owned service type for sending events"
      arg(:event_backend, :service_name)

      @desc "Use a particular owned service type for uploading files"
      arg(:storage_backend, :service_name)
      @desc "Use a particular owned service type for looking up supporters in CRM"
      arg(:detail_backend, :service_name)

      @desc "Use a particular owned service type for sending actions"
      arg(:push_backend, :service_name)

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.Org.update_org_processing/3)
    end

    @desc "Try becoming a staffer of the org"
    field :join_org, type: non_null(:join_org_result) do
      @desc "Join the org of this name"
      arg(:name, non_null(:string))

      load(:org, by: [name: :name])
      allow([:join_orgs])
      resolve(&Resolvers.Org.join_org/3)
    end

    @desc "Generate a new encryption key in org"
    field :generate_key, type: non_null(:key_with_private) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([Proca.Permission.add([:change_org_settings, :export_contacts])])

      @desc "Name of organisation"
      arg(:org_name, non_null(:string))
      arg(:input, non_null(:gen_key_input))

      resolve(&Resolvers.Org.generate_key/3)
    end

    @desc "Add a key to encryption keys"
    field :add_key, type: non_null(:key) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([Proca.Permission.add([:change_org_settings, :export_contacts])])

      @desc "Name of organisation"
      arg(:org_name, non_null(:string))
      @desc "key content"
      arg(:input, non_null(:add_key_input))

      resolve(&Resolvers.Org.add_key/3)
    end

    @desc "A separate key activate operation, because you also need to add the key to receiving system before it is used"
    field :activate_key, type: non_null(:activate_key_result) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([Proca.Permission.add([:change_org_settings, :export_contacts])])

      arg(:org_name, non_null(:string))
      @desc "Key id"
      arg(:id, non_null(:integer))

      resolve(&Resolvers.Org.activate_key/3)
    end

    @desc """
    Upsert an email tempalte to be used for sending various emails.
    It belongs to org and is identified by (name, locale), so you can have multiple "thank_you" templates for different languages.
    """
    field :upsert_template, type: :status do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_campaign_settings])

      @desc "Add email tempalte to which org"
      arg(:org_name, non_null(:string))
      @desc "Email template content"
      arg(:input, non_null(:email_template_input))

      resolve(&Resolvers.Org.upsert_template/3)
    end
  end

  # OTHER TYPES

  object :personal_data do
    @desc "Schema for contact personal information"
    field :contact_schema, non_null(:contact_schema)

    @desc "Email opt in enabled"
    field :supporter_confirm, non_null(:boolean)

    @desc "Email opt in template name"
    field :supporter_confirm_template, :string

    @desc "High data security enabled"
    field :high_security, non_null(:boolean)

    @desc "Only send thank you emails to opt-ins"
    field :doi_thank_you, non_null(:boolean)

    @desc "Enable reply_to for emails"
    field :reply_enabled, :boolean
  end

  @desc "Encryption or sign key with integer id (database)"
  object :key do
    @desc "Key id"
    field :id, non_null(:integer)
    @desc "Public part of the key (base64url)"
    field :public, non_null(:string)
    @desc "Name of the key (human readable)"
    field :name, non_null(:string)
    @desc "Is it active?"
    field :active, non_null(:boolean)
    @desc "Is it expired?"
    field :expired, non_null(:boolean)

    @desc "When the key was expired, in UTC"
    field :expired_at, :naive_datetime
  end

  object :key_with_private do
    @desc "Key id"
    field :id, non_null(:integer)
    @desc "Public part of the key (base64url)"
    field :public, non_null(:string)
    @desc "Private (Secret) part of the key (base64url)"
    field :private, non_null(:string)
    @desc "Name of the key (human readable)"
    field :name, non_null(:string)
    @desc "Is it active?"
    field :active, non_null(:boolean)
    @desc "Is it expired?"
    field :expired, non_null(:boolean)

    @desc "When the key was expired, in UTC"
    field :expired_at, :naive_datetime
  end

  object :key_ids do
    @desc "Key id"
    field :id, non_null(:integer)
    @desc "Public part of the key (base64url)"
    field :public, non_null(:string)
  end

  input_object :add_key_input do
    @desc "Name of the key"
    field :name, non_null(:string)
    @desc "Public part of the key (base64url)"
    field :public, non_null(:string)
  end

  input_object :gen_key_input do
    @desc "Name of the key"
    field :name, non_null(:string)
  end

  input_object :select_key do
    @desc "Key id"
    field :id, :integer
    @desc "Only active"
    field :active, :boolean
    @desc "Key having this public part"
    field :public, :string
  end

  object :join_org_result do
    @desc "Result of joining - succes or pending confirmation"
    field :status, non_null(:status)
    @desc "Org that was joined"
    field :org, non_null(:org)
  end

  object :activate_key_result do
    field :status, non_null(:status)
  end

  input_object :select_service do
    field :name, :service_name
  end

  object :processing do
    @desc "Envelope FROM email when sending emails"
    field :email_from, :string
    @desc "Use a particular owned service type for sending emails"
    field :email_backend, :service_name

    @desc "Is the supporter required to double opt in their action (and associated personal data)?"
    field :supporter_confirm, non_null(:boolean)
    @desc "The email template name that will be used to send the action DOI request"
    field :supporter_confirm_template, :string
    @desc "Only send thank you emails to opt-ins"
    field :doi_thank_you, non_null(:boolean)

    @desc "Should proca put action in a custom queue, so an external service can do this?"
    field :custom_supporter_confirm, non_null(:boolean)
    @desc "Should proca put action in a custom queue, so an external service can do this?"
    field :custom_action_confirm, non_null(:boolean)
    @desc "Should proca put action in custom delivery queue, so an external service can sync it?"
    field :custom_action_deliver, non_null(:boolean)
    @desc "Should proca put events in custom delivery queue, so an external service can sync it?"
    field :custom_event_deliver, non_null(:boolean)

    @desc "Use a particular owned service type for sending events"
    field :event_backend, :service_name

    @desc "Use a particular owned service type for sending actions"
    field :push_backend, :service_name
    @desc "Use a particular owned service type for uploading files"
    field :storage_backend, :service_name
    @desc "Use a particular owned service type for looking up supporters in CRM"
    field :detail_backend, :service_name

    @desc "Email templates. (warn: contant is not available to fetch)"
    field :email_templates, list_of(non_null(:string)) do
      resolve(&ProcaWeb.Resolvers.Org.org_processing_templates/3)
    end
  end

  object :email_template do
    @desc "Name of the template"
    field :name, non_null(:string)
    @desc "Locale of the template"
    field :locales, list_of(non_null(:string))
  end

  input_object :email_template_input do
    @desc "template name"
    field :name, non_null(:string)
    @desc "template locale"
    field :locale, :string
    @desc "Subject text"
    field :subject, :string
    @desc "Html part body"
    field :html, :string
    @desc "Plaintext part body"
    field :text, :string
  end
end
