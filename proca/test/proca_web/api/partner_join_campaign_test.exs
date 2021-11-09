defmodule ProcaWeb.PartnerJoinCampaignTest do 
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Factory

  use Proca.TestEmailBackend

  setup do 
    red_story()
    |> Map.put(:partner_user, insert(:user))
  end

  defp add_org_query(org) do 
    %{
      "query" => """

      fragment orgIds on Org {
        __typename
        name
        title
        ... on PrivateOrg {
          id
        }
      }

      fragment orgPrivateFields on PrivateOrg {
        __typename
        id
        personalData {
          contactSchema
          emailOptIn
          emailOptInTemplate
        }
      }

      # overview organisation info
      fragment orgInfo on PrivateOrg {
        __typename
        ...orgIds
        ...orgPrivateFields
      }

      mutation AddOrg($org: OrgInput!) {
        addOrg(input: $org) {
          config
          ...orgIds
          ...orgInfo
        }
      }
      """,
      "operationName" => "AddOrg",
      "variables" => %{
        "org" => org
      }
    }

  end

  defp public_campaigns_query(name) do 
    """
    {
      campaigns(name: "#{name}") {
        name, title, config,
        org { name, title, config }
      }
    }
    """
  end

  defp current_user_query do 
    """
      {
        currentUser {
          email 
          roles {
            org { name }
            role
          }
        }
      }
    """
  end

  defp add_page_query(vars) do 
    %{
      "operationName" => "AddActionPage",
      "variables" => vars,
      "query" => 
      """
      mutation AddActionPage(
        $orgName: String!
        $campaignName: String!
        $name: String!
        $locale: String!
      ) {
        addActionPage(
        orgName: $orgName
        campaignName: $campaignName
        name: $name
        locale: $locale
        ) {
          id name live
        }
      }
      """
      }
  end

  defp launch_page_query(name, message) do 
    """
    mutation  {
      launchActionPage(name: "#{name}", message: "#{message}") {
      status
      }
    } 
    """
  end

  defp accept_org_request(orgName, confirm) do 
    %{
      variables: %{
        org: orgName, 
        confirm: confirm
      },
      operationName: "Accept",
      query: """
      mutation Accept($org: String!, $confirm: ConfirmInput!) { 
        acceptOrgConfirm(name: $org, confirm: $confirm) {
          status
          actionPage {
            id name  live
          }
        }
      }
      """
    }
  end

  describe "yellow campaign joining by partner" do 
    test "campaign data is visible without auth", %{
      conn: conn,
      yellow_campaign: camp
        } do 

      res = api_post(conn, public_campaigns_query(camp.name))
      |> json_response(200)

      assert length(res["data"]["campaigns"]) == 1
    end

    test "org, page creation and launch request", %{
      conn: conn,
      partner_user: pu, 
      yellow_campaign: camp, yellow_user: yu
      } do 

      new_org_params = %{
        name: "purple",
        title: "Sea creatures",
        config: Jason.encode!(%{"twitter_handle" => "@sea__creature"})
      }

      res = conn
      |> auth_api_post(add_org_query(new_org_params), pu)
      |> json_response(200)

      assert %{"data" => %{"addOrg" => %{
        "name" => name2, 
        "title" => title2, 
        "config" => config2
      }}} = res

      assert name2 == new_org_params[:name]
      assert title2 == new_org_params[:title]
      assert config2 == new_org_params[:config]

      # XXX unforutnately this API does not return the privateOrg!

      res2 = conn 
      |> auth_api_post(current_user_query(), pu)
      |> json_response(200)

      assert %{"data" => %{
        "currentUser" => %{
          "email" => my_email, 
          "roles" => [%{
            "org" => %{
              "name" => ^name2
            }, 
            "role" => "owner"
          }]
        }
      }} = res2
      assert my_email == pu.email

      page_vars = %{
        orgName: "purple",
        name: "purple/yellow",
        locale: "de_DE",
        campaignName: camp.name
      }

      res3 = conn 
      |> auth_api_post(add_page_query(page_vars), pu)
      |> json_response(200)

      assert %{"data" => %{
        "addActionPage" => %{
          "id" => page_id, "live" => false
        }
      }} = res3

      assert page_id > 0

      res4 = conn 
      |> auth_api_post(launch_page_query(page_vars[:name], "please add me"), pu)
      |> json_response(200)

      assert %{"data"=> %{
        "launchActionPage" => %{
          "status" => "CONFIRMING"
        }
      }} = res4

      yellow_email = yu.email
      assert [request_email] = mailbox(yu.email)
      assert %Bamboo.Email{
        private: %{
          fields: %{
            ^yellow_email => %{
              "confirm_code" => confirm_code,
              "confirm_object_id" => confirm_object_id,
              "confirm_link" => confirm_link
            }
          },
          template_ref: "ref:launchpage"
        }
      } = request_email

      assert String.ends_with?(confirm_link, "/link/accept/#{confirm_code}?id=#{confirm_object_id}")

      res5 = conn 
      |> auth_api_post(accept_org_request("yellow", %{
        code: confirm_code, object_id: confirm_object_id
      }), yu)
      |> json_response(200)

      assert %{
        "data" => %{
          "acceptOrgConfirm" => %{
            "actionPage" => %{"id" => ^page_id, "name" => "purple/yellow", "live" => true},
            "status" => "SUCCESS"
          }
        }
      } = res5
    end
  end


end
