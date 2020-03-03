defmodule Proca.Staffer.Permission do
  use Bitwise

  @bits [
    admin: 1 <<< 0,
    access_data: 1 <<< 1,
    signoff: 1 <<< 2
  ]

  def can?(staffer, permission) when is_atom(permission) do
    bit = @bits[permission]
    (staffer.perms &&& bit) > 0
  end

  def can?(staffer, permission) when is_list(permission) do
    Enum.all?(permission, &(can? staffer, &1))
  end

  def add(perms, permission) when is_integer(perms) and is_atom(permission) do
    bit = @bits[permission]
    perms ||| bit
  end

  def add(perms, permission) when is_integer(perms) and is_list(permission) do
    Enum.reduce(permission, perms, &(add(&2, &1)))
  end

  def remove(perms, permission) when is_integer(perms) and is_atom(permission) do
    bit = @bits[permission]
    perms &&& bnot(bit)
  end

  def remove(perms, permission) when is_integer(perms) and is_list(permission) do
    Enum.reduce(permission, perms, &(remove(&2, &1)))
  end
end
