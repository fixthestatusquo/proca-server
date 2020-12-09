defmodule RolesTest do
  use Proca.DataCase
  doctest Proca.Staffer.Role
  alias Proca.{Staffer}
  alias Proca.Staffer.Role
  import Proca.Staffer.Permission, only: [can?: 2, add: 2]
  alias Ecto.Changeset

  test "can change roles" do
    staffer = Factory.build(:staffer)

    {:ok, manager} = Role.change(staffer, :owner) |> Changeset.apply_action(:update)
    assert manager |> can?([:change_org_settings, :manage_action_pages])
    refute manager |> can?(:manage_orgs)
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
