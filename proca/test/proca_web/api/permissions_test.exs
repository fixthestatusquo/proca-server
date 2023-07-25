defmodule ProcaWeb.PermissionsTest do
  @moduledoc """
  This test checks only if the user has the permission to perform an action,
  it does not check if the action actually succeeds.
  """

  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Factory

  alias Proca.QueryFixtures

  setup do
    red_story()
  end

  @scenarios_map %{
    add_campaign: %{
      owner: :succeed,
      campaigner: :succeed,
      translator: :fail
    },
    invite_user: %{
      owner: :succeed,
      campaigner: :succeed,
      translator: :succeed
    },
    update_action_page: %{
      owner: :succeed,
      campaigner: :succeed,
      translator: :fail
    }
  }

  for {query_fn, scenarios} <- @scenarios_map,
      {role, outcome} <- scenarios do
    test "role #{role} should #{outcome} to query #{query_fn}", %{
      conn: conn,
      yellow_org: org,
      yellow_ap: yellow_ap,
      yellow_user: yellow_user,
      yellow_campaigner_user: yellow_campaigner_user,
      yellow_translator_user: yellow_translator_user
    } do
      params = %{
        org_name: org.name,
        action_page_id: yellow_ap.id
      }

      query = apply(QueryFixtures, unquote(query_fn), [params])

      user =
        case unquote(role) do
          :owner -> yellow_user
          :translator -> yellow_translator_user
          :campaigner -> yellow_campaigner_user
        end

      res =
        auth_api_post(conn, query, user)
        |> json_response(200)

      if unquote(outcome) == :fail do
        assert %{
                 "errors" => [
                   %{
                     "extensions" => %{
                       "code" => "permission_denied"
                     }
                   }
                 ]
               } = res
      else
        assert %{
                 "data" => %{}
               } = res
      end
    end
  end
end
