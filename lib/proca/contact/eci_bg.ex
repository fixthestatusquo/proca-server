defmodule Proca.Contact.EciBg do
  @moduledoc """
  Bulgaria validations for ECI id numbers
  """

  @doc """
  Validation for Bulgarian UCI (EGN) number.

  More on the algorithm: https://en.wikipedia.org/wiki/Unique_citizenship_number

  This method validates the checksum and the date.
  The date is validated to be in the past and to be a real date (33th of any month will not work for example).

  @param uci a string containing the UCI number
  """
  def is_valid(uci) when is_bitstring(uci) do
    Regex.match?(~r/^[0-9]{10}$/, uci) and is_valid_date(uci) and is_valid_checksum(uci)
  end

  @doc """
  Is date valid and in past?
  """
  def is_valid_date(uci) do
    {year, month, day} = parse_date(uci)

    case Date.new(year, month, day) do
      {:ok, date} ->
        Date.compare(date, Date.utc_today()) == :lt

      _ ->
        false
    end
  end

  def parse_date(uci) do
    <<year1, year0, mon1, mon0, day1, day0, _::binary>> = uci
    [zero] = ~c"0"

    year = (year1 - zero) * 10 + (year0 - zero)
    month = (mon1 - zero) * 10 + (mon0 - zero)
    day = (day1 - zero) * 10 + (day0 - zero)

    cond do
      month > 40 -> {year + 2000, month - 40, day}
      month > 20 -> {year + 1800, month - 20, day}
      true -> {year + 1900, month, day}
    end
  end

  @checksum_weights [2, 4, 8, 5, 10, 9, 7, 3, 6]

  def is_valid_checksum(uci) do
    [zero] = ~c"0"

    numbers = String.to_charlist(uci) |> Enum.map(&(&1 - zero))

    # @checksum_weights is 9 elements, so zip leaves last from numbers
    checksum =
      Enum.zip(numbers, @checksum_weights)
      |> Enum.reduce(0, fn {c, v}, sum -> sum + c * v end)

    sum_mod =
      case rem(checksum, 11) do
        m when m < 10 -> m
        _ -> 0
      end

    List.last(numbers) == sum_mod
  end
end
