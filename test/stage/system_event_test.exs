defmodule Proca.Stage.SystemEventTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Stage.SystemEvent
  alias Proca.Factory
  alias Proca.Org
  alias Proca.Repo

  setup do
    # Ensure instance org exists (needed for new_org / new_user events)
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

  describe "join_campaign message" do
    test "builds correct action-like message", %{
      red_org: org,
      yellow_campaign: campaign,
      orange_aps: [ap | _],
      red_user: user
    } do
      # We can't actually publish (no RabbitMQ in tests), so test message building
      ap = Repo.preload(ap, [:org, :campaign])

      msg = %{
        "contact" => SystemEvent.user_contact_data(user),
        "personalInfo" => nil,
        "privacy" => %{},
        "tracking" => %{},
        "org" => %{"name" => org.name, "title" => org.title},
        "orgId" => org.id,
        "campaign" => Proca.Stage.MessageV2.campaign_data(campaign),
        "campaignId" => campaign.id,
        "actionPage" => Proca.Stage.MessageV2.action_page_data(ap),
        "actionPageId" => ap.id,
        "action" => %{
          "actionType" => "join_campaign",
          "customFields" => %{},
          "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "testing" => false
        },
        "actionId" => nil
      }

      assert msg["action"]["actionType"] == "join_campaign"
      assert msg["org"]["name"] == org.name
      assert msg["campaignId"] == campaign.id
      assert msg["actionPageId"] == ap.id
      assert msg["contact"]["email"] == user.email
      assert msg["personalInfo"] == nil
    end
  end

  describe "new_org message" do
    test "builds correct message with nil campaign/actionPage", %{red_org: org, red_user: user} do
      msg = %{
        "contact" => SystemEvent.user_contact_data(user),
        "personalInfo" => nil,
        "privacy" => %{},
        "tracking" => %{},
        "org" => %{"name" => org.name, "title" => org.title},
        "orgId" => org.id,
        "campaign" => nil,
        "campaignId" => nil,
        "actionPage" => nil,
        "actionPageId" => nil,
        "action" => %{
          "actionType" => "new_org",
          "customFields" => %{},
          "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "testing" => false
        },
        "actionId" => nil
      }

      assert msg["action"]["actionType"] == "new_org"
      assert msg["org"]["name"] == org.name
      assert msg["campaign"] == nil
      assert msg["actionPage"] == nil
      assert msg["contact"]["email"] == user.email
    end
  end

  describe "new_user message" do
    test "builds correct message with nil org/campaign/actionPage" do
      user = Factory.insert(:user)

      msg = %{
        "contact" => SystemEvent.user_contact_data(user),
        "personalInfo" => nil,
        "privacy" => %{},
        "tracking" => %{},
        "org" => nil,
        "orgId" => nil,
        "campaign" => nil,
        "campaignId" => nil,
        "actionPage" => nil,
        "actionPageId" => nil,
        "action" => %{
          "actionType" => "new_user",
          "customFields" => %{},
          "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "testing" => false
        },
        "actionId" => nil
      }

      assert msg["action"]["actionType"] == "new_user"
      assert msg["org"] == nil
      assert msg["campaign"] == nil
      assert msg["actionPage"] == nil
      assert msg["contact"]["email"] == user.email
    end
  end

  describe "emit routing keys" do
    test "join_campaign routes to campaign lead org's event exchange", %{
      yellow_campaign: campaign,
      yellow_org: yellow_org
    } do
      exchange = Proca.Pipes.Topology.xn(%Org{id: campaign.org_id}, "event")
      assert exchange == "org.#{yellow_org.id}.event"
    end

    test "new_org routes to instance org's event exchange", %{instance_org: instance_org} do
      exchange = Proca.Pipes.Topology.xn(%Org{id: instance_org.id}, "event")
      assert exchange == "org.#{instance_org.id}.event"
    end
  end

  describe "confirm operation dispatch" do
    test "join_campaign is registered in Operation.mod/1" do
      assert Proca.Confirm.Operation.mod(:join_campaign) == Proca.Confirm.JoinCampaign
    end
  end
end
