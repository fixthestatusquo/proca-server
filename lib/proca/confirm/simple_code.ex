defmodule Proca.Confirm.SimpleCode do
  @moduledoc """
  Simple numeric code generator for confirmations.
  """

  @decimals ~c"0123456789"

  def generate do
    Enum.map(1..8, fn _ -> Enum.random(@decimals) end) |> to_string()
  end
end
