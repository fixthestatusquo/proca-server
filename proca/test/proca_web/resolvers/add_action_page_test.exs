defmodule ProcaWeb.AddActionPageTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [red_story: 0]

  setup do
    red_story()
  end

  test "if red staffer can add a page to yellows campaign", %{red_org: red_org, yellow_ap: yellow_ap} do
    newname = "red.org/some-yellow-affair"
    assert {:ok, red_ap} =  ProcaWeb.Resolvers.ActionPage.copy_from(
      nil,
      %{
        name: newname,
        from_name: yellow_ap.name,
      },
      %{context: %{
           org: red_org
        }})
    assert red_ap.campaign_id == yellow_ap.campaign_id
    assert red_ap.org_id == red_org.id
    assert red_ap.extra_supporters == 0
  end



end
