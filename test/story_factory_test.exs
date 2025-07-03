defmodule Proca.StoryFactoryTest do
  use Proca.DataCase
  import Proca.StoryFactory

  describe "Red Story" do
    setup do
      red_story()
    end

    test "Red org tree", %{
      red_org: org,
      red_campaign: camp,
      red_user: user,
      red_owner: staffer,
      red_ap: ap
    } do
      assert org.id == staffer.org_id
      assert user.id == staffer.user_id
      assert camp.org_id == org.id
      assert ap.org_id == org.id
    end

    test "Yellow org tree", %{
      yellow_org: org,
      yellow_campaign: camp,
      yellow_user: user,
      yellow_owner: staffer,
      yellow_ap: ap
    } do
      assert org.id == staffer.org_id
      assert user.id == staffer.user_id
      assert camp.org_id == org.id
      assert ap.org_id == org.id
    end

    test "Partner APs", %{
      orange_aps: [ap1, ap2],
      yellow_campaign: camp,
      red_org: partner
    } do
      assert ap1.org_id == partner.id
      assert ap2.org_id == partner.id
      assert ap1.campaign_id == camp.id
      assert ap2.campaign_id == camp.id
    end
  end

  describe "Blue Story" do
    setup do
      blue_story()
    end

    test "Blue org tree", %{
      org: org,
      pages: [ap]
    } do
      assert ap.org_id == org.id
      assert Repo.one(Ecto.assoc(ap, :campaign)).org_id == org.id
    end
  end
end
