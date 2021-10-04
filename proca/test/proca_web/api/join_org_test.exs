defmodule ProcaWeb.Api.JoinOrg do 
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory
  import Ecto.Changeset
  alias Proca.{Repo,Staffer,Org}
  alias Proca.Users.User

  describe "Red org user is Admin, wants to access api of yellow" do 
    setup do 
      story = red_story()
      %{red_bot: red_bot} = story

      {:ok, red_user} = Proca.Users.User.update(red_bot.user, [:admin]) 

      %{story | red_bot: %{red_bot | user: red_user}}
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
        |> auth_api_post(query, red_user.email)
        |> json_response(200)
      assert res = %{errors: [%{
        extensions: %{code: "permission_denied"}
      }]}
    end


    test "Red bot in hq can join yellow org", %{
      conn: conn, red_bot: %{user: red_user}
        } do 
      hq = Repo.get_by Org, name: Org.instance_org_name()
      {:ok, adst} = Staffer.create(org: hq, user: red_user)

      query = """
        mutation Join {
          joinOrg(name: "yellow") {
            status
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email)
        |> json_response(200)

      assert res = %{errors: [], data: %{"joinOrg" => %{"status"=>"SUCCESS"}}}
    end

    test "Red bot with istance admin rights but no join_orgs cannot join", %{
      conn: conn, red_bot: %{user: red_user}
        } do 
      hq = Repo.get_by Org, name: Org.instance_org_name()
      {:ok, red_user} = User.update(red_user, perms: [:instance_owner])
      {:ok, adst} = Staffer.create(user: red_user, org: hq)

      query = """
        mutation Join {
          joinOrg(name: "yellow") {
            status
          }
        }
      """
      res =
        conn
        |> auth_api_post(query, red_user.email)
        |> json_response(200)

      assert res = %{errors: [%{
        extensions: %{code: "permission_denied"}
      }]}

    end

    test "Red bot can join yellow org and update page", %{
      conn: conn, red_bot: %{user: red_user}, yellow_ap: yellow_ap
        } do 

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
        |> auth_api_post(query, red_user.email)
        |> json_response(200)

      assert res = %{errors: [], data: %{
        "joinOrg" => %{"status"=>"SUCCESS"}, 
        "updateActionPage" => %{"locale" => "fr"}
        }}
    end
  end
end 
