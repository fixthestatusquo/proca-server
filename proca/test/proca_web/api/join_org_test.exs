defmodule ProcaWeb.Api.JoinOrg do 
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory
  import Ecto.Changeset
  alias Proca.{Repo,Staffer,Org}

  describe "Admin in red, wants to access api of yellow" do 
    setup do 
      story = red_story()
      {:ok, red_bot} = Staffer.Role.change(story.red_bot, :admin) |> Repo.update()

      Map.put(story, :red_bot, red_bot)
    end

    test "Red bot cannot join yellow org (not instance org)", %{
      conn: conn, red_bot: %{user: red_user}
        } do 
      query = """
        mutation Join {
          joinOrg(name: "yellow") {
            status
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email, red_user.email)
        |> json_response(200)
      assert res = %{errors: [%{
        extensions: %{code: "permission_denied"}
      }]}
    end


    test "Red bot in hq can join yellow org", %{
      conn: conn, red_bot: %{user: red_user}
        } do 
      hq = Repo.get_by Org, name: "hq"
      adst = Staffer.build_for_user(red_user, hq.id, Staffer.Role.permissions(:admin))
      |> Repo.insert!

      query = """
        mutation Join {
          joinOrg(name: "yellow") {
            status
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email, red_user.email)
        |> json_response(200)

      assert res = %{errors: [], data: %{"joinOrg" => %{"status"=>"SUCCESS"}}}
    end

    test "Red bod in hq but no join_orgs cannot join", %{
      conn: conn, red_bot: %{user: red_user}
        } do 
      hq = Repo.get_by Org, name: "hq"
      adst = Staffer.build_for_user(red_user, hq.id, 
        Staffer.Role.permissions(:admin) |> List.delete(:join_orgs)
        )
      |> Repo.insert!

      query = """
        mutation Join {
          joinOrg(name: "yellow") {
            status
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email, red_user.email)
        |> json_response(200)

      assert res = %{errors: [%{
        extensions: %{code: "permission_denied"}
      }]}

    end

    test "Red bot can join yellow org and update page", %{
      conn: conn, red_bot: %{user: red_user}, yellow_ap: yellow_ap
        } do 
      hq = Repo.get_by Org, name: "hq"
      adst = Staffer.build_for_user(red_user, hq.id, Staffer.Role.permissions(:admin))
      |> Repo.insert!

      query = """
        mutation JoinAndUpdate {
          joinOrg(name: "yellow") {
            status
          },
          updateActionPage(id: #{yellow_ap.id}) {
            input: {
              locale: "fr"
            }
          } { 
            locale
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email, red_user.email)
        |> json_response(200)

      assert res = %{errors: [], data: %{
        "joinOrg" => %{"status"=>"SUCCESS"}, 
        "updateActionPage" => %{"locale" => "fr"}
        }}
    end

  end

end 
