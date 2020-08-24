defmodule ActionPageTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  import Ecto.Query

  alias Proca.{Repo, ActionPage}

  setup do
    {:ok, red_story()}
  end

  test "red org can update their red action page by id", %{red_org: red_org, red_campaign: red_camp, red_ap: red_ap} do
    ActionPage.upsert(red_org, red_camp, %{
          id: red_ap.id,
          name: "https://stop-fires.org/petition"
                      }) |> Repo.insert_or_update!

    ap = ActionPage.find(red_ap.id)

    assert ap.name == "stop-fires.org/petition"
  end


end
