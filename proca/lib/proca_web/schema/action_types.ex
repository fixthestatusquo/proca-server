defmodule ProcaWeb.Schema.ActionTypes do
  @moduledoc """
  API for action entities
  """

  use Absinthe.Schema.Notation

  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation

  object :action_queries do
    @desc """
    Export actions collected by org, optionally filtered by campaign
    """
    field :export_actions, non_null(list_of(:action)) do
      @desc "Organization name"
      arg(:org_name, non_null(:string))
      @desc "Limit results to campaign name"
      arg(:campaign_name, :string)
      @desc "Limit results to campaign id"
      arg(:campaign_id, :integer)
      @desc "return only actions with id starting from this argument (inclusive)"
      arg(:start, :integer)
      @desc "return only actions created at date time from this argument (inclusive)"
      arg(:after, :datetime)
      @desc "Limit the number of returned actions"
      arg(:limit, :integer)

      @desc "Only download opted in contacts and actions (default true)"
      arg(:only_opt_in, :boolean)

      @desc "Only download double opted in contacts"
      arg(:only_double_opt_in, :boolean)

      @desc "Also include testing actions"
      arg(:include_testing, :boolean)

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:export_contacts])

      resolve(&Resolvers.ExportActions.export_actions/3)
    end
  end

  object :action_mutations do
    @desc "Adds an action referencing contact data via contactRef"
    field :add_action, type: non_null(:contact_reference) do
      arg(:action_page_id, non_null(:integer))
      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "Contact reference"
      arg(:contact_ref, non_null(:id))

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      resolve(&Resolvers.Action.add_action/3)
    end

    @desc "Adds an action with contact data"
    field :add_action_contact, type: non_null(:contact_reference) do
      arg(:action_page_id, non_null(:integer))

      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "GDPR communication opt"
      arg(:contact, non_null(:contact_input))

      @desc "Signature action data"
      arg(:privacy, non_null(:consent_input))

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      @desc "Links previous actions with just reference to this supporter data"
      arg(:contact_ref, :id)

      resolve(&Resolvers.Action.add_action_contact/3)
    end

    @desc "Link actions with refs to contact with contact reference"
    field :link_actions, type: non_null(:contact_reference) do
      @desc "Action Page id"
      arg(:action_page_id, non_null(:integer))

      @desc "Contact reference"
      arg(:contact_ref, non_null(:id))

      @desc "Link actions with these references (if unlinked to supporter)"
      arg(:link_refs, list_of(non_null(:string)))

      resolve(&Resolvers.Action.link_actions/3)
    end

    @desc "Requeue actions into one of processing destinations"
    field :requeue_actions, type: non_null(:requeue_result) do
      @desc "Organization name"
      arg(:org_name, non_null(:string))

      @desc "Action Ids"
      arg(:ids, list_of(non_null(:integer)))

      @desc "Destination queue"
      arg(:queue, non_null(:queue))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:export_contacts])

      resolve(&Resolvers.Action.requeue/3)
    end
  end

  @desc "Contact information"
  input_object :contact_input do
    @desc "Full name"
    field :name, :string
    @desc "First name (when you provide full name split into first and last)"
    field :first_name, :string
    @desc "Last name (when you provide full name split into first and last)"
    field :last_name, :string
    @desc "Email"
    field :email, :string
    @desc "Contacts phone number"
    field :phone, :string
    @desc "Date of birth in format YYYY-MM-DD"
    field :birth_date, :date

    @desc "Contacts address"
    field :address, :address_input

    @desc "Nationality information"
    field :nationality, :nationality_input
  end

  @desc "Address type which can hold different addres fields."
  input_object :address_input do
    @desc "Country code (two-letter)."
    field :country, :string

    @desc "Postcode, in format correct for country locale"
    field :postcode, :string

    @desc "Locality, which can be a city/town/village"
    field :locality, :string

    @desc "Region, being province, voyevodship, county"
    field :region, :string

    @desc "Street name"
    field :street, :string

    @desc "Street number"
    field :street_number, :string

    # @desc "List of areas this address belongs to"
    # field :areas, list_of(non_null(:area_input))

    # field :latitute, :float
    # field :longitute, :float
  end

  input_object :nationality_input do
    @desc "Nationality / issuer of id document"
    field :country, non_null(:string)

    @desc "Document type"
    field :document_type, :string

    @desc "Document serial id/number"
    field :document_number, :string
  end

  # field :areas -- commented above
  #   @desc "Type to describe an area (identified by area_code) in some administrative division (area_type). Area code can be an official code or just a name, provided they are unique."
  #   input_object :area_input do
  #     field :area_code, :string
  #     field :area_type, :string
  #   end

  @desc "Custom field added to action. For signature it can be contact, for mail it can be subject and body"
  input_object :action_input do
    @desc "Action Type"
    field :action_type, non_null(:string)

    @desc "Custom fields added to action"
    field :custom_fields, :json

    @desc "Deprecated format: Other fields added to action"
    field :fields, list_of(non_null(:custom_field_input)), deprecate: "use custom_fields"

    @desc "Donation payload"
    field :donation, :donation_action_input

    @desc "MTT payload"
    field :mtt, :mtt_action_input

    @desc "Test mode"
    field :testing, :boolean
  end

  object :action do
    @desc "Id of action"
    field :action_id, non_null(:integer)
    @desc "Timestamp of creation"
    field :created_at, non_null(:naive_datetime)
    @desc "Action type"
    field :action_type, non_null(:string)
    @desc "supporter contact data"
    field :contact, non_null(:contact)
    @desc "Action custom fields (as stringified JSON)"
    field :custom_fields, non_null(:json)

    @desc "Deprecated, use customFields"
    field :fields, non_null(list_of(non_null(:custom_field))), deprecate: "use custom_fields" do
      resolve(fn action, _p, _c ->
        {:ok, Proca.Field.map_to_list(action.custom_fields)}
      end)
    end

    @desc "UTM codes"
    field :tracking, :tracking
    @desc "Campaign this action was collected in"
    field :campaign, non_null(:campaign)
    @desc "Action page this action was collected at"
    field :action_page, non_null(:action_page)
    @desc "Consents, privacy data of this action"
    field :privacy, non_null(:consent)
    @desc "Donation specific data"
    field :donation, :donation
  end

  object :contact do
    @desc "Contact ref (fingerprint) of supporter"
    field :contact_ref, non_null(:id)
    @desc "Stringified json with PII optionally encrypted"
    field :payload, non_null(:string)
    @desc "Encryption nonce value"
    field :nonce, :string
    @desc "Public key used to encrypt this action"
    field :public_key, :key_ids
    @desc "Signing key used to encrypt this action"
    field :sign_key, :key_ids
    #   field :optIn, non_null(:boolean) <- is in privacy already
  end

  @desc "Custom field with a key and value. Both are strings."
  input_object :custom_field_input do
    field :key, non_null(:string)
    field :value, non_null(:string)

    @desc "Unused. To mark action_type/key as transient, use campaign.transient_actions list"
    field :transient, :boolean
  end

  @desc "Custom field with a key and value."
  object :custom_field do
    field :key, non_null(:string)
    field :value, non_null(:string)
  end

  @desc "GDPR consent data structure"
  input_object :consent_input do
    @desc "Has contact consented to receiving communication from widget owner? Null: not asked"
    field :opt_in, :boolean
    @desc "Opt in to the campaign leader"
    field :lead_opt_in, :boolean
  end

  @desc "GDPR consent data for this org"
  object :consent do
    @desc "communication (email) opt-in"
    field :opt_in, :boolean
    @desc "Consent timestamp"
    field :given_at, non_null(:naive_datetime)
    @desc "Email status, whether it's normal, DOI, or bouncing"
    field :email_status, non_null(:email_status)
    @desc "When did the email status change last time"
    field :email_status_changed, :naive_datetime

    @desc "This action contained consent (if false, it could be a share action that is attached to another action containing a consent)"
    field :with_consent, non_null(:boolean)
  end

  @desc "Tracking codes (UTM params)"
  object :tracking do
    field :source, non_null(:string)
    field :medium, non_null(:string)
    field :campaign, non_null(:string)
    field :content, non_null(:string)
  end

  @desc "Tracking codes, utm medium/campaign/source default to 'unknown', content to empty string"
  input_object :tracking_input do
    field :source, :string
    field :medium, :string
    field :campaign, :string
    field :content, :string

    @desc "Action page location. Url from which action is added. Must contain schema, domain, (port), pathname"
    field :location, :string
  end

  object :contact_reference do
    @desc "Contact's reference"
    field :contact_ref, non_null(:string)

    @desc "Contacts first name"
    field :first_name, :string
  end

  input_object :donation_action_input do
    @desc "Provide payload schema to validate, eg. stripe_payment_intent"
    field :schema, :donation_schema
    @desc "Provide amount of this donation, in smallest units for currency"
    field :amount, :integer
    @desc "Provide currency of this donation"
    field :currency, :string
    @desc "How often is the recurring donation collected"
    field :frequency_unit, :donation_frequency_unit
    @desc "Custom JSON data"
    field :payload, non_null(:json)
  end

  input_object :mtt_action_input do
    @desc "Subject line"
    field :subject, :string

    @desc "Body"
    field :body, :string

    @desc "Target ids"
    field :targets, non_null(list_of(non_null(:string)))

    @desc "Files to attach (images allowed)"
    field :files, list_of(non_null(:string))
  end

  object :donation do
    field :schema, :donation_schema
    @desc "Provide amount of this donation, in smallest units for currency"
    field :amount, non_null(:integer)
    @desc "Provide currency of this donation"
    field :currency, non_null(:string)
    @desc "Donation data"
    field :payload, non_null(:json)
    @desc "Donation frequency unit"
    field :frequency_unit, non_null(:donation_frequency_unit)
  end

  object :requeue_result do
    @desc "Count of actions selected for requeueing"
    field :count, non_null(:integer)
    @desc "Count of actions that could not be requeued"
    field :failed, non_null(:integer)
    # field :last_id, non_null(:integer)
  end
end
