defmodule ProcaWeb.TargetsTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [red_story: 0]

  setup do
    red_story()
  end

  test "adds targets to campaign", %{red_campaign: red_campaign, yellow_campaign: yellow_campaign} do
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
          external_id: "1234"
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
          external_id: "1244"
        }
      ],
      campaign_id: red_campaign.id
    }
    assert {:ok, targets} = ProcaWeb.Resolvers.Target.upsert_targets(nil, targets, nil)

    red_camp = Proca.Campaign
    |> where(id: ^red_campaign.id)
    |> preload(targets: [:emails])
    |> Proca.Repo.one

    target = Enum.at(red_camp.targets, 0)

    assert target.name == "Test Target"
    assert Enum.count(target.emails) == 2
  end
end
