defmodule Proca.Permission do
  use Bitwise
  alias Proca.Staffer
  alias Proca.Users.User
  alias Proca.Auth

  @moduledoc """
  Permission bits used in proca.
  Should be named with a verb_noun (_owner is an exception here).

  manage - add/delete/update objects
  change - change some object's association or properties

  Right now the permissions in relation to Org are on the Staffer, and 
  global permissions are in User. This is why this module should be moved up in module tree.
  """

  @bits [
    # Admin permissions [in users.perms]
    instance_owner: 1 <<< 0,
    join_orgs: 1 <<< 1,
    manage_users: 1 <<< 2,
    manage_orgs: 1 <<< 3,

    # Staffer permissions [in staffers.perms]
    org_owner: 1 <<< 7,
    # XXX deprecated - we go full API so this will be unused
    use_api: 1 <<< 8,
    export_contacts: 1 <<< 9,
    change_org_users: 1 <<< 15,
    change_org_settings: 1 <<< 16,
    # sames as change_org_settings, maybe will be split in the future
    change_org_services: 1 <<< 16,
    manage_campaigns: 1 <<< 17,
    manage_action_pages: 1 <<< 18,
    # XXX this is unused but maybe could be usefull for moderation
    launch_action_page: 1 <<< 19,
    change_campaign_settings: 1 <<< 20
  ]

  @admin_bits 0x0F 

  @spec can?(Auth | User | Staffer | nil, [atom] | atom | number) :: boolean

  # XXX change into macros?
  # Auth context: pass to legacy methods
  def can?(%Auth{user: user, staffer: nil}, permission), do: can?(user, permission)
  def can?(%Auth{user: user, staffer: staffer}, permission), do: can?(%Staffer{staffer | user: user}, permission)

  # staffer with user set: check both org and user params
  def can?(%Staffer{perms: org_perms, user: %User{perms: user_perms}}, permission) when is_number(permission) do
    ((org_perms ||| user_perms) &&& permission) > 0
  end

  # only staffer given! check it, but raise error if user perms are checked
  def can?(%Staffer{perms: org_perms}, permission) when is_number(permission) do
    if (@admin_bits &&& permission) == 0 do 
      (org_perms &&& permission) > 0
    else 
      raise ArgumentError, message: "Cannot check user permission when User is not loaded on Staffer"
    end
  end

  # just user
  def can?(%User{perms: user_perms}, permission) when is_number(permission) do 
    (user_perms &&& permission) > 0
  end

  # atomic permission - retrieve bit value
  def can?(user_or_staffer, permission) when is_atom(permission) do 
    case @bits[permission] do
      bit when is_nil(bit) -> raise ArgumentError, message: "No such permission #{permission}"
      bit -> can?(user_or_staffer, bit)
    end
  end

  # permission list - check all
  def can?(user_or_staffer, permission) when is_list(permission) do
    Enum.all?(permission, &can?(user_or_staffer, &1))
  end

  # false on nil value
  def can?(user_or_staffer, _perms) when is_nil(user_or_staffer) do
    false
  end

  def add(perms, permission) when is_integer(perms) and is_atom(permission) do
    bit = @bits[permission]
    perms ||| bit
  end

  def add(perms, permission) when is_integer(perms) and is_list(permission) do
    Enum.reduce(permission, perms, &add(&2, &1))
  end

  def add(perms, permission) when is_integer(perms) and is_integer(permission) do
    perms ||| permission
  end

  def add(permission) when is_list(permission), do: add(0, permission)

  def remove(perms, permission) when is_integer(perms) and is_atom(permission) do
    bit = @bits[permission]
    perms &&& bnot(bit)
  end

  def remove(perms, permission) when is_integer(perms) and is_list(permission) do
    Enum.reduce(permission, perms, &remove(&2, &1))
  end

  def remove(perms, permission) when is_integer(perms) and is_integer(permission) do
    perms &&& bnot(permission)
  end

  def staffer(perms) when is_integer(perms) do
    perms &&& 0xFFF0
  end

  def user(perms) when is_integer(perms) do
    perms &&& 0xF
  end

  def to_list(perms) when is_integer(perms) do
    Enum.filter(@bits, fn {_p, b} -> (b &&& perms) > 0 end)
    |> Enum.map(fn {p, _b} -> p   end)
  end
end

