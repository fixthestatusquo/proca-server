defmodule ProcaWeb.Schema.ActionTypes do
  @moduledoc """
  API for action entities
  """
  
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Schema.Authenticated

  object :action_queries do
    field :export_actions, :actions_export do
      middleware Authenticated

      arg :org_name, non_null(:string)
      arg :campaign_id, :integer
      @desc "return only actions with id starting from this argument (inclusive)"
      arg :start, :integer
      @desc "return only actions created at date time from this argument (inclusive)"
      arg :after, :datetime
      @desc "Limit the number of returned actions"
      arg :limit, :integer

    end
    # authenticated action exporting
  end

  object :action_mutations do
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
    field :birth_date, :string
    @desc "Contacts address"
    field :address, :address_input
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

    # @desc "List of areas this address belongs to"
    # field :areas, list_of(non_null(:area_input))

    # field :latitute, :float
    # field :longitute, :float
  end

  @desc "Custom field added to action. For signature it can be contact, for mail it can be subject and body"
  input_object :action_input do
    @desc "Action Type"
    field :action_type, non_null(:string)
    @desc "Other fields that accompany the signature"
    field :fields, list_of(non_null(:custom_field_input))
  end

  object :action do
    field :action_type, non_null(:string)
    field :fields, non_null(list_of(non_null(:custom_field)))
  end

  @desc "Custom field with a key and value. Both are strings."
  input_object :custom_field_input do
    field :key, non_null(:string)
    field :value, non_null(:string)
    field :transient, :boolean
  end

  @desc "Custom field with a key and value."
  object :custom_field do
    field :key, non_null(:string)
    field :value, non_null(:string)
  end

  @desc "GDPR consent data structure"
  input_object :consent_input do
    @desc "Has contact consented to receiving communication from widget owner?"
    field :opt_in, non_null(:boolean)
    field :lead_opt_in, :boolean
  end

  @desc "Tracking codes"
  input_object :tracking_input do
    field :source, non_null(:string)
    field :medium, non_null(:string)
    field :campaign, non_null(:string)
    field :content, :string
  end

  object :contact_reference do
    @desc "Contact's reference"
    field :contact_ref, :string

    @desc "Contacts first name"
    field :first_name, :string
  end

  object :actions_export do
    field :list, non_null(list_of(non_null(:action)))
  end


end
