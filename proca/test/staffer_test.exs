defmodule StafferTest do
  use Proca.DataCase
  doctest Proca.Staffer
  alias Proca.Staffer

  test "Find user not in org" do
    org_a = Factory.insert(:org)
    org_b = Factory.insert(:org)
    org_c = Factory.insert(:org)
    user_x = Factory.insert(:user)
    staffer_xa = Factory.insert(:staffer, user: user_x, org: org_a)
    staffer_xb = Factory.insert(:staffer, user: user_x, org: org_b)

    user_not_in_c = Staffer.not_in_org(org_c.id)
    assert length(user_not_in_c) == 1
  end
end
