defmodule ProcaWeb.Api.ActionPageLegacyUrlTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]

  setup do
    red_story()
  end

  test "Can fetch Action Page by url", %{conn: conn, red_ap: red_ap} do
    query = """
      query apByUrl {
        actionPage(url: "#{red_ap.name}") {
          id, name
        }
      }
    """

    res = conn
    |> api_post(query)
    |> json_response(200)
    |> is_success

    assert res["data"]["actionPage"]["id"] == red_ap.id
  end

  test "Campaign upsert by red or using urls", %{conn: conn, red_org: red_org, red_bot: red_bot} do
    query = """
    mutation uc {
       declareCampaign(
         org_name: "#{red_org.name}",
         externalId: 123,
         name: "new_one",
         title: "New one",
         actionPages: [
         {url: "https://red-alert.org/en", locale: "en"},
         {url: "https://red-alert.org/pl", locale: "pl"}
      ]) {
        id
      }
    }
    """

    res = conn
    |> auth_api_post(query, red_bot.user.email)
    |> json_response(200)
    |> is_success

    cid = res["data"]["declareCampaign"]["id"]

    query2 = """
    query gc {
      actionPage(url: "https://red-alert.org/en") {
        campaign {
          id, title
        },
        locale
      }
    }
    """

    res = conn
    |> auth_api_post(query2, red_bot.user.email)
    |> json_response(200)

    assert is_nil res["errors"]
    
    assert res["data"]["actionPage"] == %{"locale" => "en", "campaign" => %{"id" => cid, "title" => "New one"}}
  end


end
