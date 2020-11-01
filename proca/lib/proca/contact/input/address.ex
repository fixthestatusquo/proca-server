defmodule Proca.Contact.Input.Address do
  use Ecto.Schema
  import Ecto.Changeset
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
    ch
    |> cast(params, [:country, :postcode, :region, :locality, :street, :street_number])
  end
end
