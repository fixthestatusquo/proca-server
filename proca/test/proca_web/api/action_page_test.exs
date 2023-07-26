defmodule ProcaWeb.Api.ActionPageTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]

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
