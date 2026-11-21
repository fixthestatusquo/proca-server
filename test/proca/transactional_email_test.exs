defmodule Proca.TransactionalEmailTest do
  use Proca.DataCase, async: true

  alias Proca.{Factory, Org, Repo}
  alias Proca.Service.EmailTemplate
  alias Proca.TransactionalEmail, as: TE
  alias Proca.TransactionalEmail.Effective

  setup do
    org = Factory.insert(:org)
    campaign = Factory.insert(:campaign, org: org)
    ap = Factory.insert(:action_page, org: org, campaign: campaign)

    %{org: org, campaign: campaign, ap: ap}
  end

  defp set!(scope, role, attrs) do
    {:ok, te} = TE.set(scope, role, attrs)
    te
  end

  defp errors(cs), do: Enum.map(cs.errors, fn {f, {msg, _}} -> {f, msg} end)

  describe "set/3 and clear/2" do
    test "stores one row per role and scope, updating on repeat", %{org: org} do
      set!(org, :thank_you, %{state: :on})
      set!(org, :thank_you, %{template_ref: "ty"})

      assert [%TE{state: :on, template_ref: "ty"}] = TE.chain(:thank_you, org)
      assert Repo.aggregate(TE, :count) == 1
    end

    test "sets the scope ids from the scope struct", %{org: org, campaign: campaign, ap: ap} do
      o = set!(org, :thank_you, %{state: :on})
      c = set!(campaign, :thank_you, %{state: :on})
      a = set!(ap, :thank_you, %{state: :on})

      assert {o.org_id, o.campaign_id, o.action_page_id} == {org.id, nil, nil}
      assert {c.org_id, c.campaign_id, c.action_page_id} == {org.id, campaign.id, nil}
      assert {a.org_id, a.campaign_id, a.action_page_id} == {org.id, nil, ap.id}
      assert Enum.map([o, c, a], &TE.level/1) == [:org, :campaign, :action_page]
    end

    test "accepts string values (as they come from the API)", %{org: org} do
      assert %TE{state: :off, mechanism: :own_template} =
               set!(org, :duplicate, %{"state" => "off", "mechanism" => "own_template"})
    end

    test "empty template_ref is stored as nil (inherit)", %{org: org} do
      assert %TE{template_ref: nil} = set!(org, :thank_you, %{template_ref: ""})
    end

    test "clear/2 removes the row", %{ap: ap} do
      set!(ap, :thank_you, %{state: :on})
      assert :ok = TE.clear(ap, :thank_you)
      assert TE.get(ap, :thank_you) == nil
      assert :ok = TE.clear(ap, :thank_you)
    end

    test "rejects an unknown role", %{org: org} do
      assert {:error, cs} = TE.set(org, :newsletter, %{state: :on})
      assert {:role, "is invalid"} in errors(cs)
    end

    test "external_queue is only valid for supporter_confirm", %{org: org} do
      assert %TE{mechanism: :external_queue} =
               set!(org, :supporter_confirm, %{mechanism: :external_queue})

      for role <- [:thank_you, :supporter_confirm_reminder, :duplicate] do
        assert {:error, cs} = TE.set(org, role, %{mechanism: :external_queue})
        assert {:mechanism, "external_queue is only valid for supporter_confirm"} in errors(cs)
      end
    end

    test "instance-only roles are rejected outside the instance org", %{
      org: org,
      campaign: campaign
    } do
      for scope <- [org, campaign] do
        assert {:error, cs} = TE.set(scope, :user_reset_password, %{state: :on})
        assert {:role, "user_reset_password can only be set on the instance org"} in errors(cs)
      end
    end

    test "instance-only roles can be set on the instance org" do
      instance = Org.one([:instance])
      assert %TE{state: :on} = set!(instance, :user_reset_password, %{state: :on})
    end
  end

  describe "config validation" do
    test "reminder accepts its keys (atom or string keys)", %{org: org} do
      te = set!(org, :supporter_confirm_reminder, %{config: %{delay_hours: 48, max_count: 2}})
      assert te.config == %{"delay_hours" => 48, "max_count" => 2}
    end

    test "reminder rejects unknown keys and bad values", %{org: org} do
      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder, %{config: %{"delay_days" => 2}})

      assert {:config, "unknown key delay_days for role supporter_confirm_reminder"} in errors(cs)

      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder, %{config: %{"delay_hours" => 0}})

      assert {:config, "delay_hours must be a positive integer"} in errors(cs)

      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder, %{config: %{"max_count" => "3"}})

      assert {:config, "max_count must be zero or a positive integer"} in errors(cs)
    end

    test "roles without config settings reject a config", %{org: org} do
      assert {:error, cs} = TE.set(org, :thank_you, %{config: %{"x" => 1}})
      assert {:config, "is not supported for role thank_you"} in errors(cs)

      assert %TE{} = set!(org, :thank_you, %{config: %{}})
    end
  end

  describe "chain/2" do
    test "action page chain is ap, campaign, org; only stored rows", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      assert TE.chain(:thank_you, ap) == []

      set!(org, :thank_you, %{state: :on})
      set!(ap, :thank_you, %{template_ref: "ap_ty"})

      assert [:action_page, :org] = TE.chain(:thank_you, ap) |> Enum.map(&TE.level/1)

      set!(campaign, :thank_you, %{state: :off})

      assert [:action_page, :campaign, :org] = TE.chain(:thank_you, ap) |> Enum.map(&TE.level/1)

      assert [:campaign, :org] = TE.chain(:thank_you, campaign) |> Enum.map(&TE.level/1)
      assert [:org] = TE.chain(:thank_you, org) |> Enum.map(&TE.level/1)
    end

    test "ignores other roles, other pages and other campaigns", %{org: org, ap: ap} do
      other_campaign = Factory.insert(:campaign, org: org)
      other_ap = Factory.insert(:action_page, org: org, campaign: other_campaign)

      set!(org, :duplicate, %{state: :on})
      set!(other_ap, :thank_you, %{state: :on})
      set!(other_campaign, :thank_you, %{state: :on})

      assert TE.chain(:thank_you, ap) == []
    end

    test "partner page: org level comes from the page's org, campaign level from the campaign",
         %{org: owner, campaign: campaign} do
      partner = Factory.insert(:org)
      partner_ap = Factory.insert(:action_page, org: partner, campaign: campaign)

      set!(owner, :thank_you, %{template_ref: "owner_ty"})
      set!(partner, :thank_you, %{template_ref: "partner_ty"})
      set!(campaign, :thank_you, %{state: :on})

      assert [%TE{campaign_id: c_id}, %TE{org_id: p_id, template_ref: "partner_ty"}] =
               TE.chain(:thank_you, partner_ap)

      assert c_id == campaign.id
      assert p_id == partner.id
    end
  end

  describe "effective/2" do
    test "defaults when nothing is stored", %{ap: ap} do
      assert %Effective{state: :off, mechanism: :own_template, template_ref: nil, config: %{}} =
               TE.effective(:thank_you, ap)
    end

    test "each field resolves on its own, most specific first", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      set!(org, :supporter_confirm, %{state: :on, template_ref: "org_confirm"})
      set!(campaign, :supporter_confirm, %{template_ref: "campaign_confirm"})
      set!(ap, :supporter_confirm, %{mechanism: :own_template})

      assert %Effective{state: :on, mechanism: :own_template, template_ref: "campaign_confirm"} =
               TE.effective(:supporter_confirm, ap)
    end

    test "off blocks a parent's on", %{org: org, campaign: campaign, ap: ap} do
      set!(org, :supporter_confirm, %{state: :on, template_ref: "c"})
      set!(campaign, :supporter_confirm, %{state: :off})

      assert %Effective{state: :off} = TE.effective(:supporter_confirm, ap)
      refute TE.enabled?(:supporter_confirm, ap)

      set!(ap, :supporter_confirm, %{state: :on})
      assert TE.enabled?(:supporter_confirm, ap)
    end

    test "system_template defaults template_ref to the role name", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: :on, mechanism: :system_template})
      assert %Effective{template_ref: "thank_you"} = TE.effective(:thank_you, ap)

      set!(ap, :thank_you, %{template_ref: "special"})
      assert %Effective{template_ref: "special"} = TE.effective(:thank_you, ap)
    end

    test "external_queue has no template_ref", %{org: org, ap: ap} do
      set!(org, :supporter_confirm, %{
        state: :on,
        mechanism: :external_queue,
        template_ref: "ignored"
      })

      assert %Effective{mechanism: :external_queue, template_ref: nil} =
               TE.effective(:supporter_confirm, ap)

      assert TE.enabled?(:supporter_confirm, ap)
    end

    test "on without a template name is not enabled", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: :on})
      refute TE.enabled?(:thank_you, ap)
    end

    test "config keys merge, most specific wins per key; nil inherits", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      set!(org, :supporter_confirm_reminder, %{config: %{delay_hours: 48, max_count: 3}})
      set!(campaign, :supporter_confirm_reminder, %{config: %{max_count: 1}})
      set!(ap, :supporter_confirm_reminder, %{config: %{delay_hours: 24, max_count: nil}})

      assert %Effective{config: %{"delay_hours" => 24, "max_count" => 1}} =
               TE.effective(:supporter_confirm_reminder, ap)

      assert %Effective{config: %{"delay_hours" => 48, "max_count" => 1}} =
               TE.effective(:supporter_confirm_reminder, campaign)
    end
  end

  describe "template/3" do
    defp insert_template(org, name, locale \\ "en") do
      EmailTemplate.changeset(%{
        org: org,
        name: name,
        locale: locale,
        subject: "Subject #{name}",
        text: "text",
        html: "<p>html</p>"
      })
      |> Repo.insert!()
    end

    test "off and external_queue", %{org: org, ap: ap} do
      assert :off = TE.template(:supporter_confirm, ap, "en")

      set!(org, :supporter_confirm, %{state: :on, mechanism: :external_queue})
      assert :external_queue = TE.template(:supporter_confirm, ap, "en")
    end

    test "own_template is found in the page's org", %{org: org, ap: ap} do
      insert_template(org, "ty")
      set!(ap, :thank_you, %{state: :on, template_ref: "ty"})

      assert {:ok, %EmailTemplate{name: "ty"}, %Org{id: org_id}} =
               TE.template(:thank_you, ap, "en")

      assert org_id == org.id
    end

    test "own_template on a partner page is looked up in the partner org", %{
      org: owner,
      campaign: campaign
    } do
      partner = Factory.insert(:org)
      partner_ap = Factory.insert(:action_page, org: partner, campaign: campaign)

      insert_template(owner, "confirm")
      set!(campaign, :supporter_confirm, %{state: :on, template_ref: "confirm"})

      # the template only exists in the owner's org
      assert :not_found = TE.template(:supporter_confirm, partner_ap, "en")

      insert_template(partner, "confirm")

      assert {:ok, %EmailTemplate{name: "confirm"}, %Org{id: p_id}} =
               TE.template(:supporter_confirm, partner_ap, "en")

      assert p_id == partner.id
    end

    test "system_template is looked up in the instance org", %{org: org, ap: ap} do
      instance = Org.one([:instance])
      insert_template(instance, "duplicate")
      set!(org, :duplicate, %{state: :on, mechanism: :system_template})

      assert {:ok, %EmailTemplate{name: "duplicate"}, %Org{id: i_id}} =
               TE.template(:duplicate, ap, "en")

      assert i_id == instance.id
    end

    test "on but missing template is :not_found", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: :on})
      assert :not_found = TE.template(:thank_you, ap, "en")

      set!(org, :thank_you, %{template_ref: "does_not_exist"})
      assert :not_found = TE.template(:thank_you, ap, "en")
    end
  end

  describe "database constraints" do
    test "a row cannot have both a campaign and an action page", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      cs =
        %TE{org_id: org.id, campaign_id: campaign.id, action_page_id: ap.id, role: :thank_you}
        |> TE.changeset(%{state: :on})

      assert {:error, cs} = Repo.insert(cs)

      assert {:action_page_id, "a row has either a campaign or an action page, not both"} in errors(
               cs
             )
    end

    test "duplicate rows per scope are rejected", %{org: org, campaign: campaign, ap: ap} do
      for ids <- [
            %{org_id: org.id},
            %{org_id: org.id, campaign_id: campaign.id},
            %{org_id: org.id, action_page_id: ap.id}
          ] do
        insert = fn ->
          struct(TE, Map.put(ids, :role, :thank_you))
          |> TE.changeset(%{state: :on})
          |> Repo.insert()
        end

        assert {:ok, _} = insert.()
        assert {:error, cs} = insert.()
        assert {:role, "has already been taken"} in errors(cs)
      end
    end

    test "rows are deleted with their scope", %{org: org, campaign: campaign, ap: ap} do
      set!(ap, :thank_you, %{state: :on})
      Repo.delete!(ap)
      assert TE.get(ap, :thank_you) == nil

      set!(campaign, :thank_you, %{state: :on})
      Repo.delete!(campaign)
      assert TE.get(campaign, :thank_you) == nil

      assert %TE{} = set!(org, :thank_you, %{state: :on})
    end
  end
end
