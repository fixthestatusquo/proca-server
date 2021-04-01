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
      |> Proca.Contact.Input.upcase(:country)

    ch
    |> cast(params, [:country, :document_type, :document_number])
    |> validate_required(:country)
    |> Input.validate_country_format()
    |> validate_format(:document_type, ~r/^[a-z_.]+$/)
    |> validate_length(:document_type, max: 20)
    |> update_change(:document_number, &String.replace(&1, ~r/[ .-]/, ""))
    |> validate_format(:document_number, ~r/^[A-Z0-9._-]+$/i)
    |> validate_length(:document_number, max: 32)
  end
end
