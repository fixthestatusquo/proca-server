defmodule ProcaWeb.Schema.InputTypes do
  use Absinthe.Schema.Notation

  @desc "Type to describe an area (identified by area_code) in some administrative division (area_type). Area code can be an official code or just a name, provided they are unique."
  input_object :area_input do
    field :area_code, :string
    field :area_type, :string
  end

  @desc "Address type which can hold different addres fields."
  input_object :address_input do
    @desc "Country code (two-letter)."
    field :country, :string
    @desc "Postcode, in format correct for country locale"
    field :postcode, :string
    # @desc "List of areas this address belongs to"
    # field :areas, list_of(non_null(:area_input))

    # field :latitute, :float
    # field :longitute, :float
  end

  @desc "Custom field with a key and value. Both are strings."
  input_object :custom_field_input do
    field :key, :string
    field :value, :string
  end


  # NAME
  input_object :split_name_input do
    field :first_name, :string
    field :last_name, :string
  end

  input_object :full_name_input do
    field :full_name, :string
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
    @desc "Contacts address"
    @desc "Address object"
    field :address, :address_input
  end

  @desc "Extra data added to signature.
  Has optional comment and custom fields."
  input_object :signature_extra_input do
    @desc "Comment to signature"
    field :comment, :string
    @desc "Other fields that accompany the signature"
    field :custom_fields, list_of(non_null(:custom_field_input))
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

  @desc "Custom field added to action. For signature it can be contact, for mail it can be subject and body"
  input_object :action_input do
    @desc "Action Type"
    field :action_type, non_null(:string)
    @desc "Other fields that accompany the signature"
    field :fields, list_of(non_null(:custom_field_input))
  end

  @desc "ActionPage declaration"
  input_object :action_page_input do
    @desc """
    Unique URL identifying ActionPage.

    Does not have to exist, must be unique. Can be a 'technical' identifier
    scoped to particular organization, so it does not have to change when the
    slugs/urls change (eg. https://some.org/1234). However, frontent Widget can
    ask for ActionPage by it's current location.href, in which case it is useful
    to make this url match the real idwget location.
    """
    field :url, non_null(:string)

    @desc "2-letter, lowercase, code of ActionPage language"
    field :locale, non_null(:string)

    @desc "A reference to thank you email template of this ActionPage"
    field :thank_you_template_ref, :string

    @desc """
    Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. 
    """
    field :extra_supporters, :integer
  end
end
