defmodule Proca.Users.StrongPassword do
  @moduledoc """
  Password generator for users
  """
  use RandomPassword, alpha: 16, decimal: 4, symbol: 2
end
