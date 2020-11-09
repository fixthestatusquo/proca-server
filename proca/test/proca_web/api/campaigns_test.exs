defmodule ProcaWeb.Campaigns do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory

  describe "campaigns API" do
    setup do
      blue_story()
    end

    test "get campaings list by", %{conn: conn, pages: [action_page]} do
      query = """
      {
         campaigns(name: "whales") {
                id, title
         }
      }
      """

      res =
        conn
        |> api_post(query)
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "campaigns" => [
                   %{"id" => action_page.campaign.id, "title" => action_page.campaign.title}
                 ]
               }
             }
    end

    test "filter campaigns by title", %{conn: conn, org: org} do
      Factory.insert(:campaign, name: "whale-donate", title: "Donate for blue whale", org: org)

      query = """
      {
        campaigns(title: "%whale%") {
        title
        }
      }
      """

      res =
        conn
        |> api_post(query)
        |> json_response(200)

      assert Enum.map(res["data"]["campaigns"], &Map.get(&1, "title")) == [
               "Save the whales!",
               "Donate for blue whale"
             ]
    end
  end
end
