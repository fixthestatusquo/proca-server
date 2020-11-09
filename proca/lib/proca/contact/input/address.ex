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
    params = params
    |> Input.upcase_country()

    ch
    |> cast(params, [:country, :postcode, :region, :locality, :street, :street_number])
    |> Input.validate_country_format()
  end
end
