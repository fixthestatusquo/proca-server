defmodule ProcaWeb.Api.UserRolesTest do
  use ProcaWeb.ConnCase

  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Permission, only: [remove: 2]

  alias Ecto.Changeset
  alias Proca.{Repo, Staffer}

  setup do
    red_story()
  end

  test "current user roles classify legacy owner as owner", %{
    conn: conn,
    yellow_user: user,
    yellow_owner: owner
  } do
    owner
    |> Changeset.change(perms: remove(owner.perms, :delete_contacts))
    |> Repo.update!()

    res =
      conn
      |> auth_api_post(current_user_query(), user)
      |> json_response(200)

    assert %{
             "data" => %{
               "currentUser" => %{
                 "roles" => [
                   %{
                     "org" => %{"name" => "yellow"},
                     "role" => "owner"
                   }
                 ]
               }
             }
           } = res

    staffer = Staffer.for_user_in_org(user, "yellow")
    assert staffer.perms == remove(owner.perms, :delete_contacts)
  end

  defp current_user_query do
    """
    {
      currentUser {
        roles {
          org { name }
          role
        }
      }
    }
    """
  end
end
