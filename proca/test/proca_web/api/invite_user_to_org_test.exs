defmodule ProcaWeb.InviteUserToOrgTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Factory
  use Proca.TestEmailBackend

  @moduletag start: [:notify]

  setup do 
    red_story()
  end

  test "invite user by email", %{
    conn: conn, yellow_org: org, yellow_user: user 
      } do 
    
    invite_user = insert(:user)
    %{email: invite_email} = invite_user

    ## Send the invitation

    res = auth_api_post(conn, invite_user_query(invite_email, org.name), user)
    |> json_response(200)

    owner_perms = Proca.Permission.add(0, Proca.Staffer.Role.permissions(:owner))

    assert %{
      "data" => %{
        "inviteOrgUser" => %{
          "code" => code,
          "email" => ^invite_email, 
          "message" => "Welcome to our team",
          "objectId" => ^owner_perms
        }
      }
    } = res

    [invitation] = mailbox(invite_email)
    assert %{
      provider_options: %{
        fields: %{
          "code" => ^code,
          "email" => ^invite_email
        }
      }
    } = invitation

    ## Accept the invite

    res2 = auth_api_post(conn, accept_invite(invite_email, code), invite_user)
    |> json_response(200)

    assert %{ 
      "data" => %{
        "acceptUserConfirm" => %{"status" => "SUCCESS"}
      }
    } = res2 


    st = Proca.Staffer.one(user: invite_user, org: org)
    assert not is_nil st
    assert st.perms == owner_perms
  end

    

  defp invite_user_query(email, orgName) do 
    """
    mutation {
      inviteOrgUser(orgName: "#{orgName}", message: "Welcome to our team", input: {email: "#{email}", role: "owner"})  {
        code email objectId message
      }
    }
    """
  end

  defp accept_invite(email, code) do 
    """
      mutation {
        acceptUserConfirm(confirm: {email: "#{email}", code: "#{code}"}) {
          status
        }
      }
    """
  end
end
