defmodule ProcaWeb.CampaignResolverTest do
  use ProcaWeb.ConnCase

  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Repo 
  import Ecto.Query, only: [from: 2]

  alias Proca.{Repo, Action, Supporter}

  setup do
    red_story()
  end

  def list_query do
    %{
      "operationName" => "List", "variables" => %{"title" => "%"},
      "query" => """
      query List($title: String)  {
      campaigns(title: $title) {
      id, name, title, __typename
      }
      }
      """}
  end

  def get_query(vars) do
    %{
      "operationName" => "Get", "variables" => vars,
      "query" => """
      query Get($name: String, $id: Int, $externalId: Int)  {
      campaign(name: $name, id: $id, externalId: $externalId) {
        id, name, title, __typename
      }
      }
      """}
  end

  def add_query(name, input) do
    %{
      "operationName" => "Add", "variables" => %{"orgName" => name, "input" => input},
      "query" => """
      mutation Add($orgName: String, $input: CampaignInput)  {
      addCampaign(orgName: $orgName, input: $input) {
        id, name, title, __typename
        org { name }
      }
      }
      """}
  end

  def delete_query(ids) do
    %{
      "operationName" => "Del", "variables" => ids,
      "query" => """
      mutation Del($id: Int, $externalId: Int, $name: String)  {
        deleteCampaign(id: $id, externalId: $externalId, name: $name)
      }
      """
    }
  end


  test "list all campaigns", %{
    conn: conn, red_campaign: c1, yellow_campaign: c2
  } do
    q = list_query()

    res = api_post(conn, q)
    |> json_response(200)

    assert length(res["data"]["campaigns"]) == 2
  end


  test "get one campaign", %{
    conn: conn, red_campaign: c1, yellow_campaign: c2, red_user: user
  } do
    q = get_query(%{"id" => c1.id})

    res = api_post(conn, q)
    |> json_response(200)

    assert %{"title" => "Donate blood", "__typename" => "PublicCampaign"} = res["data"]["campaign"]

    res = auth_api_post(conn, q, user)
    |> json_response(200)

    assert %{"title" => "Donate blood", "__typename" => "PrivateCampaign"} = res["data"]["campaign"]

    q = get_query %{"name" => c2.name}
    res = api_post(conn, q)
    |> json_response(200)

    assert %{"title" => "Donate beer"} = res["data"]["campaign"]
  end


  test "add campaign", %{
    conn: conn, red_org: org, red_user: user
  } do
    q = add_query(org.name, %{
          "name" => "test-adding",
          "title" => "Testing adding of campaign"
                  })

    res = auth_api_post(conn, q, user)
    |> json_response(200)

    org_name = org.name

    assert %{
      "data" => %{
        "addCampaign" => %{
          "__typename" => "PrivateCampaign",
          "name" => "test-adding",
          "title" => "Testing adding of campaign",
          "org" => %{"name" => ^org_name}
        }
      }
    } = res
  end


  test "cannot delete campaign with partner pages", %{
    conn: conn, yellow_campaign: camp, yellow_user: user, orange_aps: [partner_ap|_]
  } do
    q = delete_query(%{"id" => camp.id})
    res = auth_api_post(conn, q, user)
    |> json_response(200)

    assert [%{"message" => "has action pages"}] = res["errors"]
  end

  test "can delete campaign with only local pages", %{
    conn: conn, red_campaign: camp, red_ap: page, red_user: user
  } do
    q = delete_query(%{"id" => camp.id})
    res = auth_api_post(conn, q, user)
    |> json_response(200)

    assert res["data"]["deleteCampaign"] == "SUCCESS"
    assert is_nil Proca.ActionPage.one(id: page.id)
  end
end
