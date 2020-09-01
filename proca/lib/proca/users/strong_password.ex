defmodule Proca.Users.StrongPassword do
  use RandomPassword, alpha: 16, decimal: 4, symbol: 2
end
