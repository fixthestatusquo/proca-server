defmodule Proca.Stage.SystemEventTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Stage.SystemEvent
  alias Proca.Factory
  alias Proca.Org
  alias Proca.Repo

  setup do
    # Ensure instance org exists (needed for org.add / user.add events)
    instance_org =
      case Org.one([:instance]) do
        nil -> Repo.insert!(%Org{name: "instance", title: "Instance Org"})
        org -> org
      end

    story = red_story()
    Map.put(story, :instance_org, instance_org)
  end

  describe "user_contact_data/1" do
    test "builds contact from user" do
      user = Factory.insert(:user)
      contact = SystemEvent.user_contact_data(user)

      assert contact["email"] == user.email
      assert contact["firstName"] == user.email |> String.split("@") |> List.first()
      assert contact["dupeRank"] == 0
      assert contact["contactRef"] == nil
      assert contact["area"] == nil
    end

    test "handles nil email" do
      user = %Proca.Users.User{email: nil}
      contact = SystemEvent.user_contact_data(user)
      assert contact["firstName"] == nil
      assert contact["email"] == nil
    end
  end

  describe "campaign_join_data/4" do
    test "puts the joining org, the campaign and the requester", %{
      red_org: org,
      yellow_campaign: campaign,
      orange_aps: [ap | _],
      red_user: user
    } do
      msg = SystemEvent.campaign_join_data(user, org, campaign, ap)

      assert msg["action"]["actionType"] == "campaign.join"
      assert msg["action"]["customFields"] == %{}
      assert msg["org"]["name"] == org.name
      assert msg["orgId"] == org.id
      assert msg["campaignId"] == campaign.id
      assert msg["actionPageId"] == ap.id
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == user.id
    end
  end

  describe "org_add_data/2" do
    test "puts the org and the creator", %{red_org: org, red_user: user} do
      msg = SystemEvent.org_add_data(user, org)

      assert msg["action"]["actionType"] == "org.add"
      assert msg["org"]["name"] == org.name
      assert msg["orgId"] == org.id
      assert msg["campaign"] == nil
      assert msg["actionPage"] == nil
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == user.id
    end
  end

  describe "user_add_data/1" do
    test "puts the user as contact, with no org/campaign" do
      user = Factory.insert(:user)
      msg = SystemEvent.user_add_data(user)

      assert msg["action"]["actionType"] == "user.add"
      assert msg["org"] == nil
      assert msg["campaign"] == nil
      assert msg["actionPage"] == nil
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == user.id
    end
  end

  describe "user_join_data/4" do
    test "org is the joined org; role goes in customFields", %{red_org: org} do
      actor = Factory.insert(:user)
      user = Factory.insert(:user)

      msg = SystemEvent.user_join_data(actor, user, org, :campaigner)

      assert msg["action"]["actionType"] == "user.join"
      assert msg["action"]["customFields"] == %{"role" => "campaigner"}
      assert msg["orgId"] == org.id
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == actor.id
      assert msg["campaign"] == nil
    end
  end

  describe "user_update_data/4" do
    test "role change carries only the role", %{red_org: org} do
      actor = Factory.insert(:user)
      user = Factory.insert(:user)

      msg = SystemEvent.user_update_data(actor, user, org, %{"role" => "manager"})

      assert msg["action"]["actionType"] == "user.update"
      assert msg["action"]["customFields"] == %{"role" => "manager"}
      assert msg["orgId"] == org.id
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == actor.id
    end

    test "profile change carries changed field names and no org" do
      actor = Factory.insert(:user)
      user = Factory.insert(:user)

      msg = SystemEvent.user_update_data(actor, user, nil, %{"fields" => ["job_title"]})

      assert msg["org"] == nil
      assert msg["orgId"] == nil
      assert msg["action"]["customFields"] == %{"fields" => ["job_title"]}
    end
  end

  describe "user_email_update_data/2" do
    test "actionType is updateEmail with empty customFields and no org" do
      actor = Factory.insert(:user)
      user = Factory.insert(:user)

      msg = SystemEvent.user_email_update_data(actor, user)

      assert msg["action"]["actionType"] == "updateEmail"
      assert msg["action"]["customFields"] == %{}
      assert msg["org"] == nil
      assert msg["orgId"] == nil
      assert msg["contact"]["email"] == user.email
      assert msg["user"]["id"] == actor.id
    end
  end

  describe "Support.user_data/1" do
    test "builds id + email from a user" do
      user = Factory.insert(:user)

      assert Proca.Stage.Support.user_data(user) == %{"id" => user.id, "email" => user.email}
    end

    test "returns nil when there is no user" do
      assert Proca.Stage.Support.user_data(nil) == nil
    end
  end

  describe "campaign.update message" do
    test "includes the acting user", %{yellow_campaign: campaign, red_user: user} do
      data = Proca.Stage.Event.metadata(:"campaign.update", campaign)

      result = Proca.Stage.Event.put_data(data, :"campaign.update", campaign, user: user)

      assert result[:user] == %{"id" => user.id, "email" => user.email}
    end

    test "omits user when no actor is passed", %{yellow_campaign: campaign} do
      data = Proca.Stage.Event.metadata(:"campaign.update", campaign)

      result = Proca.Stage.Event.put_data(data, :"campaign.update", campaign, [])

      refute Map.has_key?(result, :user)
    end
  end

  describe "routing keys" do
    test "campaign.update routes under system.", %{yellow_campaign: campaign} do
      assert Proca.Stage.Event.routing_key(:"campaign.update", campaign) ==
               "system.campaign.update"
    end
  end

  describe "confirm operation dispatch" do
    test "join_campaign is registered in Operation.mod/1" do
      assert Proca.Confirm.Operation.mod(:join_campaign) == Proca.Confirm.JoinCampaign
    end
  end
end
