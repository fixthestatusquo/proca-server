defmodule Proca.Contact.ItCiData do
  @moduledoc """
  Data format for Italian Citizens' Initiative
  """
  alias Proca.Contact.{ItCiData, EciData, EciDataRules, Input}
  use Ecto.Schema
  # require Proca.Contact.EciDataRules
  import Ecto.Changeset

  # Proca.Contact.EciDataRules.schema()

  embedded_schema do
    field :email, :string

    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date

    field :country, :string
    field :postcode, :string
    field :city, :string
    field :street, :string
    field :street_number, :string

    field :area, :string  # https://en.wikipedia.org/wiki/List_of_postal_codes_in_Italy - get from 1st 2 digits of postcode

    embeds_one :nationality, Input.Nationality
  end

  def required_document_types() do 
    ["driving.licence" | EciDataRules.required_document_types("IT")]
  end

  def validate_nationality(ch = %{valid?: false}), do: ch

  def validate_nationality(ch = %{valid?: true}) do
    IO.inspect(get_change(get_change(ch, :nationality), :document_number), label: "BEFORE")
    nationality =
      get_change(ch, :nationality)
      |> validate_required(:country)
      |> validate_inclusion(:country, ["IT"])
      |> update_change(:document_number, &String.replace(&1, ~r/[ -]/, ""))
      |> EciData.validate_document_type(required_document_types())
      |> EciData.validate_document_number("IT")

    IO.inspect(get_change(nationality, :document_number), label: "AFTER")

    put_embed(ch, :nationality, nationality)
  end

  def validate_address(ch = %{valid?: false}), do: ch

  def validate_address(ch) do
    case get_change(ch, :address) do
      nil ->
        ch

      address ->
        residence_country = get_change(address, :country)
        address =
          address
          |> validate_required([:country, :locality, :postcode, :street])
          |> update_change(:postcode, &String.replace(&1, ~r/[ -]/, ""))
          |> validate_format(:postcode, EciDataRules.postcode_format(residence_country))

        put_embed(ch, :address, address)
    end
  end

  def validate_personal(ch = %{valid?: false}), do: ch

  def validate_personal(ch) do
    ch
    |> validate_required([:first_name, :last_name, :birth_date])
    |> Input.validate_older(:birth_date, 18)
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    ch =
      params
      |> Input.Contact.changeset()
      |> validate_required([:nationality, :address])
      |> validate_nationality()
      |> validate_address()
      |> validate_personal()

    if ch.valid? do
      d = apply_changes(ch)
      a = Map.get(d, :address, %Input.Address{})

      change(%ItCiData{}, %{
        first_name: d.first_name,
        last_name: d.last_name,
        birth_date: d.birth_date,
        nationality: d.nationality,
        country: a.country,
        postcode: a.postcode,
        city: a.locality,
        street: a.street,
        street_number: a.street_number,
        area: Proca.Contact.ItRegions.postcode_to_region(a.postcode)
      })
    else
      ch
    end
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.ItCiData do
  alias Proca.Contact.ItCiData
  alias Proca.Contact

  def to_contact(data = %ItCiData{}, _action_page) do
    Contact.build(data)
  end

  def fingerprint(%ItCiData{
        nationality: %{country: c, document_number: dn, document_type: dt}
      })
      when not is_nil(dn) and not is_nil(dt) and not is_nil(c) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    hash = :crypto.hash(:sha256, seed <> c <> dt <> dn)
    hash
  end

  def fingerprint(data = %ItCiData{}) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]

    cont =
      [:country, :first_name, :last_name, :birth_date, :postcode]
      |> Enum.reduce( fn f, s ->
        if f == :birth_date and data.birth_date do
          s <> Date.to_string(data.birth_date)
        else
          s <> Map.get(data, f, "")
        end
      end)

    :crypto.hash(:sha256, seed <> cont)
  end
end


