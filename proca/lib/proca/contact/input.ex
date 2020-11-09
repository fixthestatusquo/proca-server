defmodule Proca.Contact.Input do
  alias Ecto.Changeset
  alias Proca.{ActionPage, Contact}
  alias Proca.Contact.Input
  import Ecto.Changeset

  @doc """
  Accepts attributes and returns a (virtual) validated data changeset
  """
  @callback from_input(map()) :: Changeset.t

  @email_format Regex.compile! "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$"
  def validate_email(chst, field) do
    chst
    |> Changeset.validate_format(field, @email_format)
  end

  @phone_format ~r{[0-9+ -]+}
  def validate_phone(chst, field) do
    chst
    |> Changeset.validate_format(field, @phone_format)
  end

  def validate_older(chst, field, years) do
    {:ok, today} = DateTime.now("Etc/UTC")
    today = DateTime.to_date(today)
    Changeset.validate_change(chst, field, fn field, dt ->
      case Date.compare(today, %{dt | year: dt.year + years}) do
        :gt -> []
        :eq -> []  # year is complete day before anniversary of birth
        :lt -> [{field, {"Age below limit", [minimum_age: years]}}]
      end
    end)
  end

  def upcase_country(params) do
    Map.update(params, :country, nil, fn
      cc when is_nil(cc) -> nil
      cc -> String.upcase(cc)
    end)
  end

  def validate_country_format(%Ecto.Changeset{} = ch) do
    validate_format(ch, :country, ~r/[A-Z]{2}/)
  end
end
