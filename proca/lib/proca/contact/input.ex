defmodule Proca.Contact.Input do
  @moduledoc """
  When api resolver validates contact map, it can use these helper funcitons.
  """
  alias Ecto.Changeset
  import Ecto.Changeset

  @doc """
  Accepts attributes and returns a (virtual) validated data changeset
  """
  @callback from_input(map()) :: Changeset.t()

  @email_format Regex.compile!(
                  "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$"
                )
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
        # year is complete day before anniversary of birth
        :eq -> []
        :lt -> [{field, {"Age below limit", [minimum_age: years]}}]
      end
    end)
  end

  def validate_name(chst, field) do
    chst
    |> Changeset.update_change(field, &String.trim/1)
    |> validate_format(field, ~r/^[\p{L}'’]([ \p{L},'’.-]*[\p{L}.])?$/u)
  end

  def validate_address_line(chst, field) do
    chst
    |> validate_format(field, ~r/^[ \p{L}0-9`“"‘’',.(&\/)-]*$/u)
  end

  def validate_postcode(chst) do
    chst
    |> validate_format(:postcode, ~r/^[A-Z0-9- ]{1,10}/)
  end

  def upcase(params, field) when is_atom(field) do
    Map.update(params, field, nil, fn
      cc when is_nil(cc) -> nil
      cc -> String.upcase(cc)
    end)
  end

  def validate_country_format(ch = %Ecto.Changeset{}) do
    validate_format(ch, :country, ~r/[A-Z]{2}/)
  end

  @doc """
  Validate if field is an url.
  Options: type: "image" - check if file extension matches mime type general class ("image/*" in this case)
  """
  def validate_url(ch = %Ecto.Changeset{}, field, opts \\ []) do
    validate_change(ch, field, fn f, uri ->
      u = URI.parse(uri)

      if Proca.Source.well_formed_url?(u) and is_url_type?(u, opts[:type]) do
        []
      else
        [{f, "URL is invalid"}]
      end
    end)
  end

  def is_url_type?(_, nil), do: true

  def is_url_type?(%URI{path: path}, type) when is_bitstring(path) do
    mime = :mimerl.extension(List.last(String.split(path, ".")))

    String.starts_with?(mime, type <> "/")
  end
end
