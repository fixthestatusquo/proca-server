defmodule Proca.Contact.EciData do
  @moduledoc """
  Data format for ECI
  """
  alias Proca.Contact.{EciData, EciDataRules, Input}
  use Ecto.Schema
  # require Proca.Contact.EciDataRules
  import Ecto.Changeset

  # Proca.Contact.EciDataRules.schema()

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date

    field :country, :string
    field :postcode, :string
    field :city, :string
    field :street, :string
    field :street_number, :string

    field :area, :string

    embeds_one :nationality, Input.Nationality
  end

  def validate_document_type(ch, []) do
    ch
  end

  def validate_document_type(ch, required_types) do
    ch
    |> validate_required([:document_type, :document_number])
    |> validate_inclusion(:document_type, required_types)
  end

  def validate_document_number(ch = %{changes: %{document_type: dt}}, country_of_nationality) do
    ch
    |> validate_required([:document_number])
    |> validate_format(
      :document_number,
      EciDataRules.document_number_format(country_of_nationality, dt)
    )
  end

  def validate_document_number(ch, _n) do
    ch
  end

  def validate_nationality(ch = %{valid?: false}), do: ch

  def validate_nationality(ch = %{valid?: true}) do
    nationality =
      get_change(ch, :nationality)
      |> validate_inclusion(:country, EciDataRules.countries())

    nationality =
      if nationality.valid? do
        case get_change(nationality, :country) do
          nil ->
            nationality

          country ->
            nationality
            |> validate_document_type(EciDataRules.required_document_types(country))
            |> validate_document_number(country)
        end
      else
        nationality
      end

    put_embed(ch, :nationality, nationality)
  end


  def validate_address(ch = %{valid?: false}), do: ch

  def validate_address(ch) do
    country = get_change(ch, :nationality) |> get_change(:country)
    address_fields = [:country, :locality, :postcode, :street]

    required_address_fields =
      EciDataRules.required(country)
      |> Enum.filter(&Enum.member?(address_fields, &1))

    case get_change(ch, :address) do
      nil ->
        ch

      address ->
        residence_country = get_change(address, :country)
        address =
          address
          |> validate_required(required_address_fields)
          |> update_change(:postcode, &String.replace(&1, ~r/[ -]/, ""))
          |> validate_format(:postcode, EciDataRules.postcode_format(residence_country))

        put_embed(ch, :address, address)
    end
  end

  def validate_personal(ch = %{valid?: false}), do: ch

  def validate_personal(ch) do
    country = get_change(ch, :nationality) |> get_change(:country)
    personal_fields = [:first_name, :last_name, :birth_date]

    required_fields =
      EciDataRules.required(country)
      |> Enum.filter(&Enum.member?(personal_fields, &1))

    ch
    |> validate_required(required_fields)
    |> Input.validate_older(:birth_date, EciDataRules.age_limit(country))
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    ch =
      params
      |> Input.Contact.changeset()
      |> validate_required(:nationality)
      |> validate_nationality()
      |> validate_address()
      |> validate_personal()

    if ch.valid? do
      d = apply_changes(ch)
      a = Map.get(d, :address) || %Input.Address{}

      change(%EciData{}, %{
        first_name: d.first_name,
        last_name: d.last_name,
        birth_date: d.birth_date,
        nationality: d.nationality,
        country: a.country,
        postcode: a.postcode,
        city: a.locality,
        street: a.street,
        street_number: a.street_number,
        area: d.nationality.country
      })
      |> validate_length(:area, max: 5)
    else
      ch
    end
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.EciData do
  alias Proca.Contact.EciData
  alias Proca.Contact

  def to_contact(data = %EciData{}, _action_page) do
    Contact.build(data)
  end

  def fingerprint(%EciData{
        nationality: %{country: c, document_number: dn, document_type: dt}
      })
      when not is_nil(dn) and not is_nil(dt) and not is_nil(c) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    hash = :crypto.hash(:sha256, seed <> c <> dt <> dn)
    hash
  end

  def fingerprint(data = %EciData{}) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]

    cont =
      [:country, :first_name, :last_name, :birth_date, :postcode]
      |> Enum.reduce("", fn f, s ->
        if f == :birth_date and data.birth_date do
          s <> Date.to_string(data.birth_date)
        else
          s <> Map.get(data, f, "")
        end
      end)

    :crypto.hash(:sha256, seed <> cont)
  end
end
