defmodule Proca.Contact.Input.Address do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Contact.Input
  @moduledoc "schema for residency address"

  embedded_schema do
    field :country, :string
    field :postcode, :string
    field :region, :string
    field :locality, :string
    field :street, :string
    field :street_number, :string
  end

  def changeset(ch, params) do
    params =
      params
      |> Input.upcase(:country)
      |> Input.upcase(:postcode)

    ch
    |> cast(params, [:country, :postcode, :region, :locality, :street, :street_number])
    |> Input.validate_country_format()
    |> Input.validate_postcode()
    |> Input.validate_address_line(:region)
    |> Input.validate_address_line(:locality)
    |> Input.validate_address_line(:street)
    |> Input.validate_address_line(:street_number)
    |> validate_length(:region, max: 64)
    |> validate_length(:locality, max: 64)
    |> validate_length(:street, max: 128)
    |> validate_length(:street_number, max: 6)
  end
end
