defmodule Proca.Contact.Input.Nationality do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Contact.Input
  @moduledoc "schema for national id"

  embedded_schema do
    field :country, :string
    field :document_type, :string
    field :document_number, :string
  end

  def changeset(ch, params) do
    params =
      params
      |> Proca.Contact.Input.upcase_country()

    ch
    |> cast(params, [:country, :document_type, :document_number])
    |> validate_required(:country)
    |> Input.validate_country_format()
  end
end
