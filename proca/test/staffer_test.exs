defmodule StafferTest do
  use Proca.DataCase
  doctest Proca.Staffer
  alias Proca.Staffer


  test "Find user not in org" do
    orgA = Factory.insert(:org)
    orgB = Factory.insert(:org)
    orgC = Factory.insert(:org)
    userX = Factory.insert(:user)
    stafferXA = Factory.insert(:staffer, user: userX, org: orgA)
    stafferXB = Factory.insert(:staffer, user: userX, org: orgB)

    userNotInC = Staffer.not_in_org(orgC.id)
    assert length(userNotInC) == 1
    
  end

end
