defmodule RolesTest do
  use Proca.DataCase
  doctest Proca.Staffer.Role
  alias Proca.Staffer.Role
  import Proca.Permission, only: [can?: 2, add: 2, remove: 2]
  alias Ecto.Changeset

  test "can change roles" do
    staffer = Factory.build(:staffer)

    {:ok, manager} = Role.change(staffer, :owner) |> Changeset.apply_action(:update)
    assert manager |> can?([:change_org_settings, :manage_action_pages, :delete_contacts])
    refute manager |> can?(:manage_orgs)
  end

  test "finds correct role" do
    staffer = Factory.build(:staffer)

    {:ok, translator} = Role.change(staffer, :translator) |> Changeset.apply_action(:update)
    assert translator |> can?([:change_org_users, :change_campaign_settings])
    refute translator |> can?(:manage_orgs)

    assert Role.findrole(translator) == :translator
  end

  test "legacy owner is still detected as owner and can assign owner role" do
    legacy_owner =
      Factory.build(:staffer, perms: add(0, Role.permissions(:owner)) |> remove(:delete_contacts))

    assert Role.findrole(legacy_owner) == :owner
    assert Role.can_assign_role?(%Proca.Auth{staffer: legacy_owner}, :owner)
    refute can?(legacy_owner, :delete_contacts)
  end

  #   test "When removing role, leave extra bits" do
  #     staffer = Factory.build(:staffer)
  #     |> Role.change(:owner)
  #     |> Changeset.apply_action(:update)
  # 
  #     assert can?(staffer, [:org_owner, :manage_campaigns])
  # 
  #     staffer = staffer
  #     |> Changeset.change(%{perms: add(staffer.perms, [:join_orgs])})
  #     |> Changeset.apply_action(:update)
  # 
  #     assert can?(staffer, [:join_orgs, :org_owner, :manage_campaigns])
  # 
  #     
  #   end

  # test "changing roles does not remove non-role permission bits" do
  #  # at the moment we do not have such permissions
  # end
end
