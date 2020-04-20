defmodule Proca.Staffer.Role do
  alias Proca.Staffer.Permission
  use Bitwise

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

  @roles [
    instance_admin: [
      :manage_orgs,
      :join_orgs,
      :change_org_settings
    ],
    campaign_manager: [
      :change_org_settings,
      :manage_campaigns,
      :manage_action_pages,
      :signoff_action_page
    ],
    campaigner: [
      :manage_campaigns,
      :manage_action_pages
    ],
    mechanic: [
      :change_org_settings,
      :use_api
    ],
    robot: [:use_api]
  ]

  def change(staffer, role) do
    np = Keyword.keys(@roles)
    |> List.keydelete(role, 0)
    |> Enum.reduce(staffer.perms, fn r, p ->
      Permission.remove(p, @roles[r])
    end)
    |> Permission.add(@roles[role])

    %{staffer | perms: np}
  end
end
