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

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow(:staffer)

      resolve(&Resolvers.Org.get_by_name/3)
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

    resolve_type(fn
      %{id: org_id}, %{context: %{auth: %Auth{staffer: %{org_id: org_id}}}} ->
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

    field :keys, non_null(list_of(non_null(:key))) do
      arg(:select, :select_key)
      resolve(&Resolvers.Org.list_keys/3)
    end

    field :key, non_null(:key) do
      arg(:select, non_null(:select_key))
      resolve(&Resolvers.Org.get_key/3)
    end

    field :services, non_null(list_of(:service)) do
      arg(:select, :select_service)
      resolve(&Resolvers.Org.list_services/3)
    end

    field :users, non_null(list_of(:org_user)) do
      resolve(&Resolvers.User.list_org_users/3)
    end

    field :processing, non_null(:processing) do
      resolve(&Resolvers.Org.org_processing/3)
    end

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

    @desc "Action Page"
    field :action_page, non_null(:action_page) do
      arg(:id, :integer)
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

    @desc "Email opt in enabled"
    field :supporter_confirm, :boolean

    @desc "Email opt in template name"
    field :supporter_confirm_template, :string

    @desc "Only send thank you emails to opt-ins"
    field :doi_thank_you, :boolean

    @desc "Config"
    field :config, :json
  end

  object :org_mutations do
    field :add_org, type: non_null(:org) do
      arg(:input, non_null(:org_input))

      allow(:user)
      resolve(&Resolvers.Org.add_org/3)
    end

    field :delete_org, type: non_null(:status) do
      @desc "Name of organisation"
      arg(:name, non_null(:string))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:org_owner])

      resolve(&Resolvers.Org.delete_org/3)
    end

    field :update_org, type: non_null(:private_org) do
      @desc "Name of organisation, used for lookup, can't be used to change org name"
      arg(:name, non_null(:string))
      arg(:input, non_null(:org_input))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.Org.update_org/3)
    end

    @desc "Update org processing settings"
    field :update_org_processing, type: non_null(:private_org) do
      @desc "Set email backend to"

      arg(:name, non_null(:string))
      arg(:email_backend, :service_name)
      arg(:email_from, :string)

      arg(:supporter_confirm, :boolean)
      arg(:supporter_confirm_template, :string)

      arg(:custom_supporter_confirm, :boolean)
      arg(:custom_action_confirm, :boolean)
      arg(:custom_action_deliver, :boolean)
      arg(:sqs_deliver, :boolean)

      arg(:event_backend, :service_name)
      arg(:event_processing, :boolean)

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.Org.update_org_processing/3)
    end

    field :join_org, type: non_null(:join_org_result) do
      arg(:name, non_null(:string))

      load(:org, by: [name: :name])
      allow([:join_orgs])
      resolve(&Resolvers.Org.join_org/3)
    end

    field :generate_key, type: non_null(:key_with_private) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([Proca.Permission.add([:change_org_settings, :export_contacts])])

      @desc "Name of organisation"
      arg(:org_name, non_null(:string))
      arg(:input, non_null(:gen_key_input))

      resolve(&Resolvers.Org.generate_key/3)
    end

    field :add_key, type: non_null(:key) do
      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([Proca.Permission.add([:change_org_settings, :export_contacts])])

      @desc "Name of organisation"
      arg(:org_name, non_null(:string))
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
  end

  @desc "Encryption or sign key with integer id (database)"
  object :key do
    field :id, non_null(:integer)
    field :public, non_null(:string)
    field :name, non_null(:string)
    field :active, non_null(:boolean)
    field :expired, non_null(:boolean)

    @desc "When the key was expired, in UTC"
    field :expired_at, :naive_datetime
  end

  object :key_with_private do
    field :id, non_null(:integer)
    field :public, non_null(:string)
    field :private, non_null(:string)
    field :name, non_null(:string)
    field :active, non_null(:boolean)
    field :expired, non_null(:boolean)

    @desc "When the key was expired, in UTC"
    field :expired_at, :naive_datetime
  end

  object :key_ids do
    field :id, non_null(:integer)
    field :public, non_null(:string)
  end

  input_object :add_key_input do
    field :name, non_null(:string)
    field :public, non_null(:string)
  end

  input_object :gen_key_input do
    field :name, non_null(:string)
  end

  input_object :select_key do
    field :id, :integer
    field :active, :boolean
    field :public, :string
  end

  object :join_org_result do
    field :status, non_null(:status)
    field :org, non_null(:org)
  end

  object :activate_key_result do
    field :status, non_null(:status)
  end

  input_object :select_service do
    field :name, :service_name
  end

  object :processing do
    field :email_from, :string
    field :email_backend, :service_name

    field :supporter_confirm, non_null(:boolean)
    field :supporter_confirm_template, :string

    field :custom_supporter_confirm, non_null(:boolean)
    field :custom_action_confirm, non_null(:boolean)
    field :custom_action_deliver, non_null(:boolean)
    field :sqs_deliver, non_null(:boolean)

    field :event_backend, :service_name
    field :event_processing, non_null(:boolean)

    field :email_templates, list_of(non_null(:string)) do
      resolve(&ProcaWeb.Resolvers.Org.org_processing_templates/3)
    end
  end
end
