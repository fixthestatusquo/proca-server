defmodule Proca.Staffer.Permission do
  use Bitwise
  alias Proca.Staffer

  @moduledoc """
  Permission bits used in proca.
  Should be named with a verb.
  """

  @bits [
    manage_orgs: 1 <<< 0,
    join_orgs: 1 <<< 1,

    use_api: 1 <<< 8,
    
    change_org_settings: 1 <<< 16,
    manage_campaigns: 1 <<< 17,
    manage_action_pages: 1 <<< 18,
    signoff_action_page: 1 <<< 19
  ]

  def can?(%Staffer{perms: perms}, permission) when is_atom(permission) do
    bit = @bits[permission]
    (perms &&& bit) > 0
  end

  def can?(staffer = %Staffer{}, permission) when is_list(permission) do
    Enum.all?(permission, &(can? staffer, &1))
  end

  def can?(staffer, _perms) when is_nil(staffer) do
    false
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
