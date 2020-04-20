defmodule RolesTest do
  use Proca.DataCase
  doctest Proca.Staffer.Role
  alias Proca.{Staffer}
  alias Proca.Staffer.Role
  import Proca.Staffer.Permission, only: [can?: 2]

  test "can change roles" do
    staffer = Factory.build(:staffer)

    manager = Role.change(staffer, :campaign_manager)
    assert manager |> can?([:change_org_settings, :signoff_action_page])
    refute manager |> can?(:manage_orgs)

    campaigner = Role.change(manager, :campaigner)
    refute campaigner |> can?(:change_org_settings)
    assert campaigner |> can?(:manage_campaigns)
  end

  # test "changing roles does not remove non-role permission bits" do
  #  # at the moment we do not have such permissions
  # end

end
