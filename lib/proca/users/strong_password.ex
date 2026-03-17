defmodule Proca.Users.StrongPassword do
  @moduledoc """
  Password generator for users.
  """

  @alphas String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
  @decimals String.graphemes("0123456789")
  @symbols String.graphemes("!#$%&()*+,-./:;<=>?@[]^_{|}~")

  def generate do
    alpha = random_chars(@alphas, 16)
    decimal = random_chars(@decimals, 4)
    symbol = random_chars(@symbols, 2)

    (alpha <> decimal <> symbol)
    |> to_charlist()
    |> Enum.shuffle()
    |> to_string()
  end

  defp random_chars(chars, n) do
    Enum.map(1..n, fn _ -> Enum.random(chars) end) |> Enum.join()
  end
end
