defmodule ProcaWeb.Schema.InputTypes do
  use Absinthe.Schema.Notation

  input_object :area_input do
    field :area_code, :string
    field :area_type, :string
  end

  input_object :address_input do
    field :country, :string
    field :postcode, :string
    field :areas, list_of(:area_input)

    field :latitute, :float
    field :longitute, :float
  end

  input_object :custom_field_input do
    field :key
    field :value
  end

  input_object :signature_input do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :address, :address_input
    field :custom_fields, list_of(:custom_field_input)
  end
end
