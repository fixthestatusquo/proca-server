defmodule ProcaWeb.UpsertActionPage do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]

  describe "upsert_campaign API" do
    setup do
      red_story()
    end

    test "red bot user can't update yellow action page", %{conn: conn, red_bot: %{user: user}, yellow_ap: ap} do
      query = """
      mutation Uap {
        updateActionPage(id: #{ap.id}, locale: "jp") {
          locale
        }
      }
      """

      res = conn
      |> auth_api_post(query, user.email)
      |> json_response(200)

      assert %{"errors" => [%{"message" => "User cannot manage this action page"}]} = res
    end

    test "red bot can update red action page by id",  %{conn: conn, red_bot: %{user: user}, red_ap: ap} do
      query = """
      mutation Uap {
      updateActionPage(id: #{ap.id},
      locale: "jp",
      url: "https://yellow.org/other",
      journey: ["sign", "share"],
      config: "{\\"foo\\": 123}") {
      id
      }
      }
      """

      res = conn
      |> auth_api_post(query, user.email)
      |> json_response(200)

      assert res["errors"] == nil
      assert res["data"]["updateActionPage"]["id"] == ap.id

      updated = Proca.Repo.get(Proca.ActionPage, ap.id)
      assert updated.config == %{"foo" => 123}
      assert updated.url == "https://yellow.org/other"
      assert updated.journey == ["sign", "share"]
    end
  end
end
