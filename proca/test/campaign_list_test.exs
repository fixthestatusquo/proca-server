defmodule CampaignListTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  import Ecto.Query

  alias Proca.{Repo, Campaign}

  setup do
    {:ok, red_story()}
  end

  test "red org has 2 campaigns", %{red_org: red_org} do
    camps = Campaign.select_by_org(red_org) |> Repo.all()
    assert Enum.count(camps) == 2
  end

  test "red org can retrieve their campaign", %{red_org: red_org, red_campaign: red_camp} do
    c =
      Campaign.select_by_org(red_org)
      |> where([c], c.id == ^red_camp.id)
      |> Repo.one()

    assert c.name == red_camp.name
  end

  test "red org can retrieve partner campaign", %{red_org: red_org, yellow_campaign: yellow_camp} do
    c =
      Campaign.select_by_org(red_org)
      |> where([c], c.id == ^yellow_camp.id)
      |> Repo.one()

    assert c.name == yellow_camp.name
  end
end
