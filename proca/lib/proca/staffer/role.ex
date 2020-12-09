defmodule Proca.Staffer.Role do
  alias Proca.Staffer.Permission
  alias Proca.Staffer
  use Bitwise
  alias Ecto.Changeset

  @moduledoc """
  What roles do we need right now?
  - Instance admin 👾

  For the organisation (they should be exclusive):
  - Campaigner (a normal org member, can add campaigns and action_pages) 🤹 (person juggling)
  - Mechanic (settings, can add people to the org, use api, etc) [woman mechanic 👩‍🔧]
  - Campaign manager (can add people to the org, sign off, delegate action pages + campaigner) [woman pilot emoji] 👩‍✈️
  - Api (robot emoji, api)  🤖

  Obviously the permission bits overlap between the roles, so the code must figure out what is the role based on bits set.
  """

  # Must be ordered from most to least capable!
  @roles [
    admin: [
      :instance_owner,
      :join_orgs,
      :manage_users,
      :manage_orgs
    ],
    owner: [
      :org_owner,
      :export_contacts,
      :change_org_users,
      :change_org_settings,
      :manage_campaigns,
      :manage_action_pages
    ]
  ]

  def from_string(rs) when is_bitstring(rs) do
    Keyword.keys(@roles)
    |> Enum.find(fn r -> Atom.to_string(r) == rs end)
  end

  def change(staffer = %Staffer{perms: perms}, role) do
    np =
      Keyword.keys(@roles)
      |> List.keydelete(role, 0)
      |> Enum.reduce(perms, fn r, p ->
        Permission.remove(p, @roles[r])
      end)
      |> Permission.add(@roles[role])

    Changeset.change(staffer, perms: np)
  end

  def findrole(%Staffer{}, []) do
    nil
  end

  def findrole(staffer = %Staffer{}, [role | other_roles]) do
    if Permission.can?(staffer, @roles[role]) do
      role
    else
      findrole(staffer, other_roles)
    end
  end

  def permissions(role) do
    @roles[role] || 0
  end
end
