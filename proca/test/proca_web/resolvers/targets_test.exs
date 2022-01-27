defmodule ProcaWeb.TargetsTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [red_story: 0]

  setup do
    red_story()
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

    assert {:ok, targets} = ProcaWeb.Resolvers.Target.upsert_targets(nil, targets, nil)

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
