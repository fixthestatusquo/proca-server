defmodule ProcaWeb.TargetsTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [red_story: 0]

  alias ProcaWeb.Resolvers.Target
  alias Proca.Campaign
  alias Proca.Factory
  alias Proca.Action.{Message, MessageContent}

  setup do
    red_story()
  end

  test "replace targets", %{
    red_campaign: red_campaign,
    red_ap: ap
  } do
    targets = [
      %{name: "Maulhausen", emails: [%{email: "mal@ec.eu"}], external_id: "1"},
      %{name: "Perrier", area: "IT", emails: [%{email: "perrire@gov.it"}], external_id: "2"}
    ]

    assert {:ok, _t} =
             Target.upsert_targets(nil, %{targets: targets, campaign_id: red_campaign.id}, nil)

    c = Campaign.one(id: red_campaign.id, preload: [:targets])
    assert length(c.targets) == 2

    {targets2, _} = Enum.split(targets, 1)

    targets2 = [
      %{name: "Newman", emails: [%{email: "newman@pe.pt"}], external_id: "3"} | targets2
    ]

    assert {:ok, [t1, t3]} =
             Target.upsert_targets(
               nil,
               %{targets: targets2, outdated_targets: :delete, campaign_id: red_campaign.id},
               nil
             )

    c = Campaign.one(id: red_campaign.id, preload: [:targets])
    assert length(c.targets) == 2
    assert t1.name == "Maulhausen"
    assert t3.name == "Newman"

    action = Factory.insert(:action, %{action_page: ap})

    msg = Factory.insert(:message, %{action: action, target: t3})

    t3_id = t3.id

    assert {:error, [%{message: "has messages", path: ["targets", ^t3_id, "messages"]}]} =
             Target.upsert_targets(
               nil,
               %{targets: targets, outdated_targets: :delete, campaign_id: red_campaign.id},
               nil
             )

    assert {:ok, [t1, t3]} =
             Target.upsert_targets(
               nil,
               %{targets: targets, outdated_targets: :disable, campaign_id: red_campaign.id},
               nil
             )
  end

  test "adds and update targets to campaign", %{
    red_campaign: red_campaign,
    yellow_campaign: yellow_campaign
  } do
    targets = %{
      targets: [
        %{
          name: "Test Target",
          emails: [
            %{
              email: "test@html.123"
            },
            %{
              email: "test@html.1234"
            }
          ],
          external_id: "t1"
        },
        %{
          name: "Test Target12",
          emails: [
            %{
              email: "test@html.1233"
            },
            %{
              email: "test@html.12344"
            }
          ],
          external_id: "t2"
        }
      ],
      campaign_id: red_campaign.id
    }

    assert {:ok, targets} = Target.upsert_targets(nil, targets, nil)

    red_camp =
      Proca.Campaign
      |> where(id: ^red_campaign.id)
      |> preload(targets: [:emails])
      |> Proca.Repo.one()

    target = Enum.find(red_camp.targets, fn %{external_id: x} -> x == "t1" end)

    assert target.name == "Test Target"
    assert Enum.count(target.emails) == 2

    # lets try to update
    targets_to_update = %{
      targets: [
        %{
          external_id: "t1",
          name: "Updated Test Target",
          emails: [%{email: "test@html.123", email_status: :unsub}]
        }
      ],
      campaign_id: red_campaign.id
    }

    assert {:ok, targets} = ProcaWeb.Resolvers.Target.upsert_targets(nil, targets_to_update, nil)

    red_camp =
      Proca.Campaign
      |> where(id: ^red_campaign.id)
      |> preload(targets: [:emails])
      |> Proca.Repo.one()

    target = Enum.find(red_camp.targets, fn %{external_id: x} -> x == "t1" end)

    assert target.name == "Updated Test Target"
    assert Enum.count(target.emails) == 1
    assert [%{email_status: :unsub} | _] = target.emails
  end
end
