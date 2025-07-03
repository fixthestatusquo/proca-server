defmodule Proca.MessageTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  import Proca.Factory

  setup do
    story = blue_story()
    [page] = story[:pages]

    {:ok, source} = Proca.Source.get_or_create_by(params_for(:source))

    action =
      insert(:action, %{
        action_page: page,
        fields: %{
          "event" => "Warsaw",
          "friends" => 3
        },
        source: source
      })

    Map.put(story, :action, action)
  end

  describe "action_data in two versions" do
    setup %{action: action, org: org} do
      %{
        msg1: Proca.Stage.MessageV1.action_data(action, :deliver, org.id),
        msg2: Proca.Stage.MessageV2.action_data(action, :deliver, org.id)
      }
    end

    test "have common keys", %{
      action: a,
      pages: [page],
      msg1: m1,
      msg2: m2
    } do
      # IO.inspect(m1, label: "1")
      # IO.inspect(m2, label: "2")
      # IO.inspect(a.with_consent, label: "has consent")

      assert "event" in Map.keys(a.fields)

      assert m1["actionId"] == a.id
      assert m1["actionPageId"] == page.id
      assert m1["campaignId"] == page.campaign.id
      assert m1["orgId"] == page.org_id
      assert m1["action"]["actionType"] == "register"
      assert m1["campaign"]["name"] == a.campaign.name
      assert m1["stage"] == "deliver"
      assert m1["contact"]["email"] == a.supporter.email
      assert m1["contact"]["firstName"] == a.supporter.first_name
      assert m1["tracking"]["campaign"] == a.source.campaign
      assert m1["tracking"]["source"] == a.source.source
      assert m1["tracking"]["medium"] == a.source.medium
      assert m1["tracking"]["location"] == a.source.location

      assert m2["actionId"] == a.id
      assert m2["actionPageId"] == page.id
      assert m2["campaignId"] == page.campaign.id
      assert m2["orgId"] == page.org_id
      assert m2["action"]["actionType"] == "register"
      assert m2["campaign"]["name"] == a.campaign.name
      assert m2["stage"] == "deliver"
      assert m2["contact"]["email"] == a.supporter.email
      assert m2["contact"]["firstName"] == a.supporter.first_name
      assert m2["tracking"]["campaign"] == a.source.campaign
      assert m2["tracking"]["source"] == a.source.source
      assert m2["tracking"]["medium"] == a.source.medium
      assert m2["tracking"]["location"] == a.source.location
    end

    test "have different keys", %{
      action: a,
      pages: [page],
      msg1: m1,
      msg2: m2
    } do
      [%Proca.Contact{payload: contact_json}] = a.supporter.contacts
      {:ok, pii} = Jason.decode(contact_json)

      assert m1["privacy"]["communication"] == true
      assert m1["action"]["fields"]["event"] == "Warsaw"
      assert m1["action"]["fields"]["friends"] == 3
      assert m1["schema"] == "proca:action:1"
      assert m1["contact"]["ref"] == Proca.Supporter.base_encode(a.supporter.fingerprint)
      assert m1["contact"]["payload"] == contact_json

      assert m2["privacy"]["optIn"] == true
      assert m2["action"]["customFields"]["event"] == "Warsaw"
      assert m2["action"]["customFields"]["friends"] == 3
      assert m2["schema"] == "proca:action:2"
      assert m2["contact"]["contactRef"] == Proca.Supporter.base_encode(a.supporter.fingerprint)
      assert m2["contact"]["personalInfo"] == nil
      assert m2["contact"]["postcode"] == pii["postcode"]
      assert m2["contact"]["country"] == pii["country"]
      assert m2["contact"]["phone"] == pii["phone"]
      assert m2["contact"]["last_name"] == pii["last_name"]
      assert m2["contact"]["first_name"] == pii["first_name"]
    end
  end
end
