defmodule Proca.Contact.EciData do
  @moduledoc """
  Data format for ECI
  """
  alias Proca.Contact.{EciData, EciDataRules, Input}
  use Ecto.Schema
  # require Proca.Contact.EciDataRules
  import Ecto.Changeset

  # Proca.Contact.EciDataRules.schema()

  defmodule Nationality do
    use Ecto.Schema
    @moduledoc "schema for national id"
    @derive Jason.Encoder
    embedded_schema do
      field :country, :string
      field :document_type, :string
      field :document_number, :string
    end
  end

  @derive Jason.Encoder
  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date

    field :country, :string
    field :postcode, :string
    field :city, :string
    field :street, :string
    field :street_number, :string

    embeds_one :nationality, Nationality
  end


  defp locality_to_city(%{locality: city} = p) do
    p
    |> Map.delete(:locality)
    |> Map.put(:city, city)
  end

  defp locality_to_city(p), do: p

  def cast_data(params, country_of_nationality)  when is_bitstring(country_of_nationality) do
    data = %EciData{}
    |> cast(params, [
          :first_name,
          :last_name,
          :birth_date,
        ])
    |> cast(Map.get(params, :address, %{}) |> locality_to_city(), [:country, :postcode, :city, :street, :street_number])
    |> validate_required(EciDataRules.required(country_of_nationality))
    |> Input.validate_older(:birth_date,  EciDataRules.age_limit(country_of_nationality))
    # the residency can be in any country 
    #   |> validate_inclusion(:country, EciDataRules.countries)

    data = data |> validate_format(:postcode, EciDataRules.postcode_format(Map.get(data.changes, :country)))
    data
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
    |> validate_format(:document_number, EciDataRules.document_number_format(country_of_nationality, dt))
  end

  def validate_document_number(ch, _n) do
    ch
  end


  def cast_nationality(nationality) do
    case %Nationality{}
    |> cast(nationality, [:country, :document_type, :document_number])
    |> validate_required(:country)
    |> validate_inclusion(:country, EciDataRules.countries)
      do
      %{valid?: true} = ch -> ch
        |> validate_document_type(EciDataRules.required_document_types(nationality.country))
        |> validate_document_number(nationality.country)
      er -> er
    end
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    with n = %Ecto.Changeset{valid?: true} <- cast_nationality(Map.get(params, :nationality, %{})),
         %{country: country_of_nationality} <- apply_changes(n),
         d = %Ecto.Changeset{valid?: true} <- cast_data(params, country_of_nationality) do
      put_embed(d, :nationality, n)
    else
      e -> e
    end
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.EciData do
  alias Proca.Contact.EciData
  alias Proca.Contact

  def to_contact(%EciData{} = data, action_page) do
    Contact.build(data)
  end

  def fingerprint(%EciData{
        nationality: %{country: c, document_number: dn, document_type: dt}
                  }) when not is_nil(dn) and not is_nil(dt) and not is_nil(c) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    hash = :crypto.hash(:sha256, seed <> c <> dt <> dn)
    hash
  end

  def fingerprint(%EciData{} = data) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]

    [:country, :first_name, :last_name, :birth_date, :postcode]
    [] |> Enum.reduce("", fn f, s ->
      if f == :birth_date and data.birth_date do
        s <> Date.to_string(data.birth_date)
      else
        s <> Map.get(s, f, "")
      end
    end)
  end
end
