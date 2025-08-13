defmodule ProcaWeb.Campaigns do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory

  describe "campaigns API" do
    setup do
      story = blue_story()
      owner = Factory.insert(:staffer, org: story.org, perms: Proca.Permission.add(Proca.Staffer.Role.permissions(:owner)))

      Map.merge(story, %{conn: build_conn(), owner: owner})
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

    test "update campaign supporter_confirm via GraphQL", %{conn: conn, org: org, owner: owner} do
      campaign =
        Factory.insert(:campaign,
          name: "supporter-camp",
          title: "Supporter Confirm Test",
          org: org
        )

      mutation = """
      mutation UpdateCampaignSupporterConfirmation($name: String!, $confirm: Boolean!, $template: String!) {
        updateCampaignSupporterConfirmation(
          name: $name,
          supporterConfirm: $confirm,
          supporterConfirmTemplate: $template
        ) {
          id
          name
          supporterConfirm
          supporterConfirmTemplate
        }
      }
      """

      variables = %{
        "name" => campaign.name,
        "confirm" => true,
        "template" => "my_template"
      }

      res =
        conn
        |> auth_api_post(%{query: mutation, variables: variables}, owner.user)
        |> json_response(200)

      data = res["data"]["updateCampaignSupporterConfirmation"]
      assert data["id"] == campaign.id
      assert data["supporterConfirm"] == true
      assert data["supporterConfirmTemplate"] == "my_template"
    end
  end
end
