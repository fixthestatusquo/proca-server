defmodule ProcaWeb.Campaigns do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0, red_story: 0]
  alias Proca.Factory

  describe "campaigns API" do
    setup do
      blue_story()
    end

    test "get campaings list by", %{conn: conn, pages: [action_page]} do
      query = """
      {
         campaigns(name: "#{action_page.campaign.name}") {
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

  describe "translator campaign API permissions" do
    setup do
      red_story()
    end

    test "translator can change campaign title", %{
      conn: conn,
      yellow_translator_user: user,
      yellow_campaign: yellow_camp
    } do
      new_title = "new_campaign_title"
      %{id: camp_id} = yellow_camp

      res =
        auth_api_post(conn, change_campaign_title_query(yellow_camp.id, new_title), user)
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateCampaign" => %{
                   "id" => ^camp_id,
                   "title" => ^new_title
                 }
               }
             } = res
    end

    test "translator can't add campaign", %{
      conn: conn,
      yellow_translator_user: user,
      yellow_org: yellow_org
    } do
      res =
        auth_api_post(conn, add_campaign_query(yellow_org.name), user)
        |> json_response(200)

      assert %{
               "errors" => [
                 %{
                   "extensions" => %{
                     "code" => "permission_denied"
                   }
                 }
               ]
             } = res
    end
  end

  defp change_campaign_title_query(id, title) do
    """
    mutation {
      updateCampaign(id: #{id}, input: {title: "#{title}"}) {
        id title
      }
    }
    """
  end

  defp add_campaign_query(org_name) do
    """
    mutation {
      addCampaign(orgName: "#{org_name}", input: {title: "campaign"}) {
        id
      }
    }
    """
  end
end
