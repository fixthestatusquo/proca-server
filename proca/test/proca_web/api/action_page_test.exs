defmodule ProcaWeb.Api.ActionPageTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0, red_story: 0]

  describe "action page API" do
    setup do
      blue_story()
    end

    test "Can fetch action page with no auth", %{conn: conn, pages: [ap]} do
      query = """
      query actionPage ($id:Int!) {
          actionPage (id:$id) {
              __typename,
              id, name, locale,
              config,
              campaign {
                  id,title,name,config,
                  org {name,title}
              },
              org {
                  title
              }
          }
      }
      """

      res =
        api_post(conn, %{query: query, variables: %{id: ap.id}})
        |> json_response(200)

      assert not is_nil(res["data"])
      assert res["data"]["actionPage"]["name"] == ap.name
      assert res["data"]["actionPage"]["__typename"] == "PublicActionPage"
    end
  end

  describe "translator action page API permissions" do
    setup do
      red_story()
    end

    test "translator can't modify action page", %{
      conn: conn,
      yellow_translator_user: user,
      yellow_ap: yellow_ap
    } do
      res =
        auth_api_post(conn, change_action_page_locale_query(yellow_ap.id), user)
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

  defp change_action_page_locale_query(id) do
    """
    mutation {
      updateActionPage(id: #{id}, input: {locale: "pl"}) {
        id
      }
    }
    """
  end
end
