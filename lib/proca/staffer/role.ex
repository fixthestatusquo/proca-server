defmodule Proca.Staffer.Role do
  alias Proca.{Permission, Staffer, Auth}
  alias Proca.Users.User
  alias Ecto.Changeset

  @moduledoc """
  For the organisation (they should be exclusive):
  - Campaigner (a normal org member, can add campaigns and action_pages) 🤹 (person juggling)
  - Mechanic (settings, can add people to the org, use api, etc) [woman mechanic 👩‍🔧]
  - Campaign manager (can add people to the org, sign off, delegate action pages + campaigner) [woman pilot emoji] 👩‍✈️
  - Api (robot emoji, api)  🤖

  Obviously the permission bits overlap between the roles, so the code must figure out what is the role based on bits set.
  """

  # 👇 Must be ordered from most to least capable!
  @roles [
    owner: [
      :org_owner,
      :export_contacts,
      :delete_contacts,
      :change_org_users,
      :change_org_settings,
      :change_campaign_settings,
      :manage_campaigns,
      :manage_action_pages
    ],
    campaigner: [
      :change_org_users,
      :change_org_settings,
      :change_campaign_settings,
      :manage_campaigns,
      :manage_action_pages
    ],
    translator: [
      :change_org_users,
      :change_campaign_settings
    ],
    coordinator: [
      :change_campaign_settings
    ]
  ]
  @legacy_owner_permissions List.delete(@roles[:owner], :delete_contacts)

  @spec from_string(String.t()) :: atom() | nil
  def from_string(rs) when is_bitstring(rs) do
    Keyword.keys(@roles)
    |> Enum.find(fn r -> Atom.to_string(r) == rs end)
  end

  def change(staffer = %Staffer{}, role) when is_atom(role) do
    Changeset.change(staffer, perms: Permission.add(0, @roles[role]))
  end

  def findrole(%Staffer{}, []) do
    nil
  end

  def findrole(staffer = %Staffer{}, [role | other_roles]) do
    if matches_role?(staffer, role) do
      role
    else
      findrole(staffer, other_roles)
    end
  end

  def findrole(staffer = %Staffer{}), do: findrole(staffer, Keyword.keys(@roles))

  def permissions(role) do
    @roles[role] || []
  end

  def legacy_owner_permissions do
    @legacy_owner_permissions
  end

  def lesser_equal?(weaker, stronger) when is_atom(weaker) and is_atom(stronger) do
    @roles[weaker] -- @roles[stronger] == []
  end

  def add_user_as(%Proca.Users.User{} = user, %Proca.Org{} = org, role) do
    case Staffer.for_user_in_org(user, org.id) do
      nil -> Staffer.changeset(%{user_id: user.id, org_id: org.id, role: role})
      st -> change(st, role)
    end
  end

  def add_user_as(email, org, role) when is_bitstring(email) do
    user = User.one(email: email)

    case user do
      nil -> {:error, :not_found}
      user -> add_user_as(user, org, role)
    end
  end

  @doc """
  Check if current user or staffer has big enough permission to assign a role
  """
  def can_assign_role?(%Auth{staffer: %Staffer{} = staffer}, role) do
    permissions(role) -- assignable_permissions(staffer) == []
  end

  def can_assign_role?(%Auth{} = auth) do
    Permission.can?(auth, :manage_users)
  end

  defp matches_role?(staffer, :owner) do
    Permission.can?(staffer, @roles[:owner]) or Permission.can?(staffer, @legacy_owner_permissions)
  end

  defp matches_role?(staffer, role) do
    Permission.can?(staffer, @roles[role])
  end

  defp assignable_permissions(staffer) do
    perms = Permission.to_list(staffer.perms)

    if matches_role?(staffer, :owner) do
      Enum.uniq(@roles[:owner] ++ perms)
    else
      perms
    end
  end
end
