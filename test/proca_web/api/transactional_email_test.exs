defmodule ProcaWeb.Api.TransactionalEmailTest do
  use ProcaWeb.ConnCase

  alias Proca.{Factory, Permission}
  alias Proca.Staffer.Role
  alias Proca.TransactionalEmail, as: TE

  @add """
  mutation Add($org: String!, $campaign: String, $page: Int,
               $role: TransactionalEmailRole!, $input: TransactionalEmailInput!) {
    addTransactionalEmail(orgName: $org, campaignName: $campaign, actionPageId: $page,
                          role: $role, input: $input) {
      id role level state mechanism templateRef config
    }
  }
  """

  @update """
  mutation Update($org: String!, $id: Int!, $input: TransactionalEmailInput!) {
    updateTransactionalEmail(orgName: $org, id: $id, input: $input) {
      id state mechanism templateRef config
    }
  }
  """

  @delete """
  mutation Delete($org: String!, $id: Int!) {
    deleteTransactionalEmail(orgName: $org, id: $id)
  }
  """

  setup do
    org = Factory.insert(:org)
    campaign = Factory.insert(:campaign, org: org)
    ap = Factory.insert(:action_page, org: org, campaign: campaign)

    partner = Factory.insert(:org)
    partner_ap = Factory.insert(:action_page, org: partner, campaign: campaign)

    %{
      conn: build_conn(),
      org: org,
      campaign: campaign,
      ap: ap,
      partner: partner,
      partner_ap: partner_ap,
      owner: staffer(org, :owner),
      coordinator: staffer(org, :coordinator),
      partner_owner: staffer(partner, :owner)
    }
  end

  defp staffer(org, role) do
    Factory.insert(:staffer, org: org, perms: Permission.add(0, Role.permissions(role))).user
  end

  defp run(conn, user, query, variables) do
    conn
    |> auth_api_post(%{query: query, variables: variables}, user)
    |> json_response(200)
  end

  defp error(res) do
    assert [%{"message" => msg} = e] = res["errors"]
    {get_in(e, ["extensions", "code"]), msg}
  end

  describe "addTransactionalEmail" do
    test "on the org, a campaign and a page", %{conn: conn, org: org, owner: owner} = ctx do
      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "role" => "SUPPORTER_CONFIRM",
          "input" => %{"state" => true, "mechanism" => "EXTERNAL_QUEUE"}
        })

      assert %{"level" => "ORG", "state" => true, "mechanism" => "EXTERNAL_QUEUE"} =
               res["data"]["addTransactionalEmail"]

      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "campaign" => ctx.campaign.name,
          "role" => "SUPPORTER_CONFIRM",
          "input" => %{"state" => false}
        })

      assert %{"level" => "CAMPAIGN", "state" => false, "mechanism" => nil} =
               res["data"]["addTransactionalEmail"]

      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "page" => ctx.ap.id,
          "role" => "SUPPORTER_CONFIRM_REMINDER1",
          "input" => %{"state" => true, "config" => ~s({"delay_hours": 48})}
        })

      assert %{"level" => "ACTION_PAGE", "config" => config} =
               res["data"]["addTransactionalEmail"]

      assert Jason.decode!(config) == %{"delay_hours" => 48}
    end

    test "role already set at that level", %{conn: conn, org: org, owner: owner} do
      vars = %{"org" => org.name, "role" => "THANK_YOU", "input" => %{"state" => true}}
      run(conn, owner, @add, vars)
      res = run(conn, owner, @add, vars)

      assert [%{"message" => msg}] = res["errors"]
      assert msg =~ "already set at this scope"
    end

    test "changeset errors come back as errors", %{conn: conn, org: org, owner: owner} do
      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "role" => "THANK_YOU",
          "input" => %{"mechanism" => "EXTERNAL_QUEUE"}
        })

      assert [%{"message" => msg}] = res["errors"]
      assert msg =~ "external_queue is only valid for supporter_confirm"
    end

    test "campaign and page together is a bad argument", %{conn: conn, owner: owner} = ctx do
      res =
        run(conn, owner, @add, %{
          "org" => ctx.org.name,
          "campaign" => ctx.campaign.name,
          "page" => ctx.ap.id,
          "role" => "THANK_YOU",
          "input" => %{"state" => true}
        })

      assert {"bad_arg", "Give campaignName or actionPageId, not both"} == error(res)
    end

    test "unknown campaign or page", %{conn: conn, org: org, owner: owner} do
      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "campaign" => "no-such-campaign",
          "role" => "THANK_YOU",
          "input" => %{"state" => true}
        })

      assert {"not_found", ~s(Campaign "no-such-campaign" not found)} == error(res)

      res =
        run(conn, owner, @add, %{
          "org" => org.name,
          "page" => 0,
          "role" => "THANK_YOU",
          "input" => %{"state" => true}
        })

      assert {"not_found", "Action page 0 not found"} == error(res)
    end

    test "a partner cannot set the campaign", %{conn: conn, partner: partner} = ctx do
      res =
        run(conn, ctx.partner_owner, @add, %{
          "org" => partner.name,
          "campaign" => ctx.campaign.name,
          "role" => "SUPPORTER_CONFIRM",
          "input" => %{"state" => true}
        })

      assert {"permission_denied", msg} = error(res)
      assert msg =~ ~s(Campaign "#{ctx.campaign.name}" belongs to another org)
      refute msg =~ ctx.org.name
    end

    test "the campaign owner cannot set a partner's page, the partner can",
         %{conn: conn, partner_ap: partner_ap} = ctx do
      vars = %{"page" => partner_ap.id, "role" => "THANK_YOU", "input" => %{"state" => true}}

      res = run(conn, ctx.owner, @add, Map.put(vars, "org", ctx.org.name))
      assert {"permission_denied", msg} = error(res)
      assert msg =~ "Action page #{partner_ap.id} belongs to another org"
      assert msg =~ "use campaignName"

      res = run(conn, ctx.partner_owner, @add, Map.put(vars, "org", ctx.partner.name))
      assert %{"level" => "ACTION_PAGE"} = res["data"]["addTransactionalEmail"]
    end

    test "org level needs change_org_settings, campaign level does not",
         %{conn: conn, org: org, coordinator: coordinator} = ctx do
      vars = %{"org" => org.name, "role" => "THANK_YOU", "input" => %{"state" => true}}

      res = run(conn, coordinator, @add, vars)
      assert {"permission_denied", _} = error(res)

      res = run(conn, coordinator, @add, Map.put(vars, "campaign", ctx.campaign.name))
      assert %{"level" => "CAMPAIGN"} = res["data"]["addTransactionalEmail"]
    end

    test "not a member of the org", %{conn: conn, org: org, partner_owner: outsider} do
      res =
        run(conn, outsider, @add, %{
          "org" => org.name,
          "role" => "THANK_YOU",
          "input" => %{"state" => true}
        })

      assert {"permission_denied", _} = error(res)
    end
  end

  describe "updateTransactionalEmail" do
    test "left out keeps the value, null inherits", %{conn: conn, ap: ap} = ctx do
      {:ok, te} = TE.add(ap, :thank_you, %{state: true, template_ref: "ty"})
      vars = %{"org" => ctx.org.name, "id" => te.id}

      res = run(conn, ctx.owner, @update, Map.put(vars, "input", %{"state" => false}))

      assert %{"state" => false, "templateRef" => "ty"} = res["data"]["updateTransactionalEmail"]

      res = run(conn, ctx.owner, @update, Map.put(vars, "input", %{"templateRef" => nil}))

      assert %{"state" => false, "templateRef" => nil} = res["data"]["updateTransactionalEmail"]
    end

    test "unknown id, or a row of another org", %{conn: conn, partner_ap: partner_ap} = ctx do
      {:ok, te} = TE.add(partner_ap, :thank_you, %{state: true})
      input = %{"state" => false}

      res = run(conn, ctx.owner, @update, %{"org" => ctx.org.name, "id" => 0, "input" => input})
      assert {"not_found", "Transactional email 0 not found"} == error(res)

      res =
        run(conn, ctx.owner, @update, %{"org" => ctx.org.name, "id" => te.id, "input" => input})

      assert {"permission_denied", "Transactional email #{te.id} belongs to another org."} ==
               error(res)
    end

    test "org-level row needs change_org_settings", %{conn: conn, org: org} = ctx do
      {:ok, te} = TE.add(org, :thank_you, %{state: true})

      res =
        run(conn, ctx.coordinator, @update, %{
          "org" => org.name,
          "id" => te.id,
          "input" => %{"state" => false}
        })

      assert {"permission_denied", _} = error(res)
    end
  end

  describe "picking a setting by role + level instead of id" do
    @update_by_key """
    mutation Update($org: String!, $id: Int, $role: TransactionalEmailRole,
                    $campaign: String, $page: Int, $input: TransactionalEmailInput!) {
      updateTransactionalEmail(orgName: $org, id: $id, role: $role,
                               campaignName: $campaign, actionPageId: $page, input: $input) {
        id state
      }
    }
    """

    @delete_by_key """
    mutation Delete($org: String!, $role: TransactionalEmailRole, $page: Int) {
      deleteTransactionalEmail(orgName: $org, role: $role, actionPageId: $page)
    }
    """

    test "update on a campaign, by role", %{conn: conn, campaign: campaign} = ctx do
      {:ok, te} = TE.add(campaign, :supporter_confirm, %{state: true})

      res =
        run(conn, ctx.owner, @update_by_key, %{
          "org" => ctx.org.name,
          "role" => "SUPPORTER_CONFIRM",
          "campaign" => campaign.name,
          "input" => %{"state" => false}
        })

      assert %{"id" => id, "state" => false} = res["data"]["updateTransactionalEmail"]
      assert id == te.id
    end

    test "update on the org, by role (no campaign or page)", %{conn: conn, org: org} = ctx do
      {:ok, _} = TE.add(org, :thank_you, %{state: true})

      res =
        run(conn, ctx.owner, @update_by_key, %{
          "org" => org.name,
          "role" => "THANK_YOU",
          "input" => %{"state" => false}
        })

      assert %{"state" => false} = res["data"]["updateTransactionalEmail"]
    end

    test "delete on a page, by role", %{conn: conn, ap: ap} = ctx do
      {:ok, _} = TE.add(ap, :duplicate, %{state: true})

      res =
        run(conn, ctx.owner, @delete_by_key, %{
          "org" => ctx.org.name,
          "role" => "DUPLICATE",
          "page" => ap.id
        })

      assert res["data"]["deleteTransactionalEmail"] == "SUCCESS"
      assert TE.get(ap, :duplicate) == nil
    end

    test "role not set at that level", %{conn: conn, org: org} = ctx do
      # set on the org, but asked for the campaign level
      {:ok, _} = TE.add(org, :thank_you, %{state: true})

      res =
        run(conn, ctx.owner, @update_by_key, %{
          "org" => org.name,
          "role" => "THANK_YOU",
          "campaign" => ctx.campaign.name,
          "input" => %{"state" => false}
        })

      assert {"not_found", "No THANK_YOU setting at this level, use addTransactionalEmail"} ==
               error(res)
    end

    test "id and role together, or neither, is a bad argument", %{conn: conn, org: org} = ctx do
      {:ok, te} = TE.add(org, :thank_you, %{state: true})
      vars = %{"org" => org.name, "input" => %{"state" => false}}

      res =
        run(
          conn,
          ctx.owner,
          @update_by_key,
          Map.merge(vars, %{"id" => te.id, "role" => "THANK_YOU"})
        )

      assert {"bad_arg", "Give id, or role (with campaignName or actionPageId), not both"} ==
               error(res)

      res = run(conn, ctx.owner, @update_by_key, vars)
      assert {"bad_arg", "Give id, or role (with campaignName or actionPageId)"} == error(res)
    end

    test "role on another org's campaign is refused", %{conn: conn, partner: partner} = ctx do
      {:ok, _} = TE.add(ctx.campaign, :thank_you, %{state: true})

      res =
        run(conn, ctx.partner_owner, @update_by_key, %{
          "org" => partner.name,
          "role" => "THANK_YOU",
          "campaign" => ctx.campaign.name,
          "input" => %{"state" => false}
        })

      assert {"permission_denied", _} = error(res)
    end
  end

  describe "org.transactionalEmail (one setting)" do
    @get """
    query($org: String!, $id: Int, $role: TransactionalEmailRole, $page: Int) {
      org(name: $org) {
        transactionalEmail(id: $id, role: $role, actionPageId: $page) { id role level templateRef }
      }
    }
    """

    test "by id and by role + level, without inheritance",
         %{conn: conn, org: org, ap: ap} = ctx do
      {:ok, _} = TE.add(org, :thank_you, %{state: true, template_ref: "org_ty"})
      {:ok, page_te} = TE.add(ap, :thank_you, %{template_ref: "page_ty"})

      res = run(conn, ctx.owner, @get, %{"org" => org.name, "id" => page_te.id})

      assert %{"level" => "ACTION_PAGE", "templateRef" => "page_ty"} =
               res["data"]["org"]["transactionalEmail"]

      res = run(conn, ctx.owner, @get, %{"org" => org.name, "role" => "THANK_YOU"})

      assert %{"level" => "ORG", "templateRef" => "org_ty"} =
               res["data"]["org"]["transactionalEmail"]

      res =
        run(conn, ctx.owner, @get, %{"org" => org.name, "role" => "THANK_YOU", "page" => ap.id})

      assert %{"level" => "ACTION_PAGE"} = res["data"]["org"]["transactionalEmail"]
    end

    test "not stored at that level", %{conn: conn, org: org, ap: ap} = ctx do
      {:ok, _} = TE.add(org, :thank_you, %{state: true})

      res =
        run(conn, ctx.owner, @get, %{"org" => org.name, "role" => "THANK_YOU", "page" => ap.id})

      assert [%{"message" => "No THANK_YOU setting at this level, use addTransactionalEmail"}] =
               res["errors"]
    end
  end

  describe "deleteTransactionalEmail" do
    test "deletes the row", %{conn: conn, campaign: campaign} = ctx do
      {:ok, te} = TE.add(campaign, :thank_you, %{state: true})

      res = run(conn, ctx.owner, @delete, %{"org" => ctx.org.name, "id" => te.id})
      assert res["data"]["deleteTransactionalEmail"] == "SUCCESS"
      assert TE.chain(:thank_you, campaign) == []
    end

    test "a row of another org is refused", %{conn: conn, partner: partner} = ctx do
      {:ok, te} = TE.add(partner, :thank_you, %{state: true})

      res = run(conn, ctx.owner, @delete, %{"org" => ctx.org.name, "id" => te.id})
      assert {"permission_denied", _} = error(res)
      assert TE.chain(:thank_you, partner) != []
    end
  end

  describe "transactionalEmails field" do
    test "page shows its chain, optionally for one role", %{conn: conn, org: org, ap: ap} = ctx do
      {:ok, _} = TE.add(org, :thank_you, %{state: true})
      {:ok, _} = TE.add(ap, :thank_you, %{template_ref: "ty"})
      {:ok, _} = TE.add(ctx.campaign, :supporter_confirm, %{state: true})

      query = """
      query($org: String!, $id: Int!, $select: SelectTransactionalEmail) {
        org(name: $org) {
          transactionalEmails { role level }
          actionPage(id: $id) {
            ... on PrivateActionPage {
              transactionalEmails(select: $select) { role level templateRef }
            }
          }
        }
      }
      """

      res = run(conn, ctx.owner, query, %{"org" => org.name, "id" => ap.id})
      org_data = res["data"]["org"]

      assert org_data["transactionalEmails"] == [%{"role" => "THANK_YOU", "level" => "ORG"}]

      assert Enum.map(org_data["actionPage"]["transactionalEmails"], &{&1["role"], &1["level"]}) ==
               [
                 {"SUPPORTER_CONFIRM", "CAMPAIGN"},
                 {"THANK_YOU", "ACTION_PAGE"},
                 {"THANK_YOU", "ORG"}
               ]

      res =
        run(conn, ctx.owner, query, %{
          "org" => org.name,
          "id" => ap.id,
          "select" => %{"role" => "SUPPORTER_CONFIRM"}
        })

      assert [%{"role" => "SUPPORTER_CONFIRM"}] =
               res["data"]["org"]["actionPage"]["transactionalEmails"]
    end
  end
end
