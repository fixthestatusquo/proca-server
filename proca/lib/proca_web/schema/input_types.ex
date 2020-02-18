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
    @desc "List of areas this address belongs to"
    field :areas, list_of(:area_input)

    field :latitute, :float
    field :longitute, :float
  end

  @desc "Custom field with a key and value. Both are strings."
  input_object :custom_field_input do
    field :key, :string
    field :value, :string
  end

  @desc "Petition signature data. Only name is mandatory.
Email and phone will be checked for format.
For address, you can pass none or many different fields that specify it.
All other fields should come in custom fields as key-value pairs.
"
  input_object :signature_input do
    @desc "Contacts name, first name first"
    field :name, :string
    @desc "Contacts email address"
    field :email, :string
    @desc "Contacts phone number"
    field :phone, :string
    @desc "Contacts address"
    field :address, :address_input
    @desc "Other fields that accompany the signature"
    field :custom_fields, list_of(:custom_field_input)
  end
end
