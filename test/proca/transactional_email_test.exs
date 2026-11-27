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
      set!(org, :thank_you, %{state: true})
      set!(org, :thank_you, %{template_ref: "ty"})

      assert [%TE{state: true, template_ref: "ty"}] = TE.chain(:thank_you, org)
      assert Repo.aggregate(TE, :count) == 1
    end

    test "sets the scope ids from the scope struct", %{org: org, campaign: campaign, ap: ap} do
      o = set!(org, :thank_you, %{state: true})
      c = set!(campaign, :thank_you, %{state: true})
      a = set!(ap, :thank_you, %{state: true})

      assert {o.org_id, o.campaign_id, o.action_page_id} == {org.id, nil, nil}
      assert {c.org_id, c.campaign_id, c.action_page_id} == {org.id, campaign.id, nil}
      assert {a.org_id, a.campaign_id, a.action_page_id} == {org.id, nil, ap.id}
      assert Enum.map([o, c, a], &TE.level/1) == [:org, :campaign, :action_page]
    end

    test "accepts string values (as they come from the API)", %{org: org} do
      assert %TE{state: false, mechanism: :own_template} =
               set!(org, :duplicate, %{"state" => "false", "mechanism" => "own_template"})
    end

    test "empty template_ref is stored as nil (inherit)", %{org: org} do
      assert %TE{template_ref: nil} = set!(org, :thank_you, %{template_ref: ""})
    end

    test "clear/2 removes the row", %{ap: ap} do
      set!(ap, :thank_you, %{state: true})
      assert :ok = TE.clear(ap, :thank_you)
      assert TE.get(ap, :thank_you) == nil
      assert :ok = TE.clear(ap, :thank_you)
    end

    test "rejects an unknown role", %{org: org} do
      assert {:error, cs} = TE.set(org, :newsletter, %{state: true})
      assert {:role, "is invalid"} in errors(cs)
    end

    test "external_queue is only valid for supporter_confirm", %{org: org} do
      assert %TE{mechanism: :external_queue} =
               set!(org, :supporter_confirm, %{mechanism: :external_queue})

      for role <- [:thank_you, :supporter_confirm_reminder1, :duplicate] do
        assert {:error, cs} = TE.set(org, role, %{mechanism: :external_queue})
        assert {:mechanism, "external_queue is only valid for supporter_confirm"} in errors(cs)
      end
    end

    test "instance-only roles are rejected outside the instance org", %{
      org: org,
      campaign: campaign
    } do
      for scope <- [org, campaign] do
        assert {:error, cs} = TE.set(scope, :user_reset_password, %{state: true})
        assert {:role, "user_reset_password can only be set on the instance org"} in errors(cs)
      end
    end

    test "instance-only roles can be set on the instance org" do
      instance = Org.one([:instance])
      assert %TE{state: true} = set!(instance, :user_reset_password, %{state: true})
    end
  end

  describe "config validation" do
    test "reminders accept delay_hours (atom or string keys)", %{org: org} do
      te = set!(org, :supporter_confirm_reminder1, %{config: %{delay_hours: 48}})
      assert te.config == %{"delay_hours" => 48}

      te = set!(org, :supporter_confirm_reminder2, %{config: %{"delay_hours" => 72}})
      assert te.config == %{"delay_hours" => 72}
    end

    test "reminder rejects unknown keys and bad values", %{org: org} do
      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder1, %{config: %{"delay_days" => 2}})

      assert {:config, "unknown key delay_days for role supporter_confirm_reminder1"} in errors(
               cs
             )

      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder2, %{config: %{"max_count" => 2}})

      assert {:config, "unknown key max_count for role supporter_confirm_reminder2"} in errors(cs)

      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder1, %{config: %{"delay_hours" => 0}})

      assert {:config, "delay_hours must be a positive integer"} in errors(cs)

      assert {:error, cs} =
               TE.set(org, :supporter_confirm_reminder1, %{config: %{"delay_hours" => "48"}})

      assert {:config, "delay_hours must be a positive integer"} in errors(cs)
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

      set!(org, :thank_you, %{state: true})
      set!(ap, :thank_you, %{template_ref: "ap_ty"})

      assert [:action_page, :org] = TE.chain(:thank_you, ap) |> Enum.map(&TE.level/1)

      set!(campaign, :thank_you, %{state: false})

      assert [:action_page, :campaign, :org] = TE.chain(:thank_you, ap) |> Enum.map(&TE.level/1)

      assert [:campaign, :org] = TE.chain(:thank_you, campaign) |> Enum.map(&TE.level/1)
      assert [:org] = TE.chain(:thank_you, org) |> Enum.map(&TE.level/1)
    end

    test "ignores other roles, other pages and other campaigns", %{org: org, ap: ap} do
      other_campaign = Factory.insert(:campaign, org: org)
      other_ap = Factory.insert(:action_page, org: org, campaign: other_campaign)

      set!(org, :duplicate, %{state: true})
      set!(other_ap, :thank_you, %{state: true})
      set!(other_campaign, :thank_you, %{state: true})

      assert TE.chain(:thank_you, ap) == []
    end

    test "partner page: org level comes from the page's org, campaign level from the campaign",
         %{org: owner, campaign: campaign} do
      partner = Factory.insert(:org)
      partner_ap = Factory.insert(:action_page, org: partner, campaign: campaign)

      set!(owner, :thank_you, %{template_ref: "owner_ty"})
      set!(partner, :thank_you, %{template_ref: "partner_ty"})
      set!(campaign, :thank_you, %{state: true})

      assert [%TE{campaign_id: c_id}, %TE{org_id: p_id, template_ref: "partner_ty"}] =
               TE.chain(:thank_you, partner_ap)

      assert c_id == campaign.id
      assert p_id == partner.id
    end
  end

  describe "effective/2" do
    test "defaults when nothing is stored", %{ap: ap} do
      assert %Effective{state: false, mechanism: :own_template, template_ref: nil, config: %{}} =
               TE.effective(:thank_you, ap)
    end

    test "each field resolves on its own, most specific first", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      set!(org, :supporter_confirm, %{state: true, template_ref: "org_confirm"})
      set!(campaign, :supporter_confirm, %{template_ref: "campaign_confirm"})
      set!(ap, :supporter_confirm, %{mechanism: :own_template})

      assert %Effective{state: true, mechanism: :own_template, template_ref: "campaign_confirm"} =
               TE.effective(:supporter_confirm, ap)
    end

    test "off blocks a parent's on", %{org: org, campaign: campaign, ap: ap} do
      set!(org, :supporter_confirm, %{state: true, template_ref: "c"})
      set!(campaign, :supporter_confirm, %{state: false})

      assert %Effective{state: false} = TE.effective(:supporter_confirm, ap)
      refute TE.enabled?(:supporter_confirm, ap)

      set!(ap, :supporter_confirm, %{state: true})
      assert TE.enabled?(:supporter_confirm, ap)
    end

    test "system_template defaults template_ref to the role name", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: true, mechanism: :system_template})
      assert %Effective{template_ref: "thank_you"} = TE.effective(:thank_you, ap)

      set!(ap, :thank_you, %{template_ref: "special"})
      assert %Effective{template_ref: "special"} = TE.effective(:thank_you, ap)
    end

    test "external_queue has no template_ref", %{org: org, ap: ap} do
      set!(org, :supporter_confirm, %{
        state: true,
        mechanism: :external_queue,
        template_ref: "ignored"
      })

      assert %Effective{mechanism: :external_queue, template_ref: nil} =
               TE.effective(:supporter_confirm, ap)

      assert TE.enabled?(:supporter_confirm, ap)
    end

    test "on without a template name is not enabled", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: true})
      refute TE.enabled?(:thank_you, ap)
    end

    test "config keys merge, most specific wins per key; nil inherits", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      set!(org, :supporter_confirm_reminder1, %{config: %{delay_hours: 48}})
      set!(campaign, :supporter_confirm_reminder1, %{state: true})
      set!(ap, :supporter_confirm_reminder1, %{config: %{delay_hours: nil}})

      # campaign sets no config and the page's nil means inherit: org's 48 wins
      assert %Effective{state: true, config: %{"delay_hours" => 48}} =
               TE.effective(:supporter_confirm_reminder1, ap)

      set!(ap, :supporter_confirm_reminder1, %{config: %{delay_hours: 24}})

      assert %Effective{config: %{"delay_hours" => 24}} =
               TE.effective(:supporter_confirm_reminder1, ap)

      assert %Effective{config: %{"delay_hours" => 48}} =
               TE.effective(:supporter_confirm_reminder1, campaign)

      # the two reminders are configured independently
      assert %Effective{config: %{}} = TE.effective(:supporter_confirm_reminder2, ap)
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

      set!(org, :supporter_confirm, %{state: true, mechanism: :external_queue})
      assert :external_queue = TE.template(:supporter_confirm, ap, "en")
    end

    test "own_template is found in the page's org", %{org: org, ap: ap} do
      insert_template(org, "ty")
      set!(ap, :thank_you, %{state: true, template_ref: "ty"})

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
      set!(campaign, :supporter_confirm, %{state: true, template_ref: "confirm"})

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
      set!(org, :duplicate, %{state: true, mechanism: :system_template})

      assert {:ok, %EmailTemplate{name: "duplicate"}, %Org{id: i_id}} =
               TE.template(:duplicate, ap, "en")

      assert i_id == instance.id
    end

    test "on but missing template is :not_found", %{org: org, ap: ap} do
      set!(org, :thank_you, %{state: true})
      assert :not_found = TE.template(:thank_you, ap, "en")

      set!(org, :thank_you, %{template_ref: "does_not_exist"})
      assert :not_found = TE.template(:thank_you, ap, "en")
    end
  end

  describe "add/3, update/2, delete/1" do
    test "add creates a row; adding the same role at the same scope again fails", %{
      campaign: campaign
    } do
      assert {:ok, %TE{campaign_id: c_id, state: true}} =
               TE.add(campaign, :supporter_confirm, %{state: true})

      assert c_id == campaign.id

      assert {:error, cs} = TE.add(campaign, :supporter_confirm, %{state: false})
      assert {:role, "is already set at this scope"} in errors(cs)
    end

    test "add checks role, mechanism and instance-only roles like set/3", %{org: org} do
      assert {:error, cs} = TE.add(org, :newsletter, %{state: true})
      assert {:role, "is invalid"} in errors(cs)

      assert {:error, _} = TE.add(org, :thank_you, %{mechanism: :external_queue})
      assert {:error, _} = TE.add(org, :user_reset_password, %{state: true})
    end

    test "update: missing keys keep their value, nil goes back to inherit", %{ap: ap} do
      {:ok, te} = TE.add(ap, :thank_you, %{state: true, template_ref: "ty"})

      assert {:ok, %TE{state: false, template_ref: "ty"}} = TE.update(te, %{state: false})

      te = Repo.reload(te)
      assert {:ok, %TE{state: nil, template_ref: "ty"}} = TE.update(te, %{state: nil})
    end

    test "delete removes the row", %{org: org} do
      {:ok, te} = TE.add(org, :thank_you, %{state: true})
      assert {:ok, _} = TE.delete(te)
      assert TE.chain(:thank_you, org) == []
    end

    test "scope_of/1 returns the row's org, campaign or page", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      for scope <- [org, campaign, ap] do
        {:ok, te} = TE.add(scope, :duplicate, %{state: true})
        assert %{__struct__: mod, id: id} = TE.scope_of(te)
        assert {mod, id} == {scope.__struct__, scope.id}
      end
    end
  end

  describe "template check on add/update" do
    setup %{org: org} do
      backend = Factory.insert(:email_backend, org: org)
      org = Repo.update!(Ecto.Changeset.change(org, email_backend_id: backend.id))
      %{org: org}
    end

    test "own_template must exist in the scope's org", %{org: org, ap: ap} do
      assert {:error, cs} = TE.add(ap, :thank_you, %{state: true, template_ref: "nope"})
      assert {:template_ref, "template nope not found in this org"} in errors(cs)

      insert_template(org, "ty")
      assert {:ok, te} = TE.add(ap, :thank_you, %{state: true, template_ref: "ty"})

      assert {:error, cs} = TE.update(te, %{template_ref: "nope"})
      assert {:template_ref, "template nope not found in this org"} in errors(cs)
    end

    test "system_template is checked in the instance org, also when inherited", %{
      org: org,
      ap: ap
    } do
      instance = Org.one([:instance])
      backend = Factory.insert(:email_backend, org: instance)
      Repo.update!(Ecto.Changeset.change(instance, email_backend_id: backend.id))

      # system_template defaults the name to the role
      assert {:error, cs} = TE.add(org, :duplicate, %{state: true, mechanism: :system_template})
      assert {:template_ref, "template duplicate not found in the instance org"} in errors(cs)

      insert_template(instance, "duplicate")
      {:ok, _} = TE.add(org, :duplicate, %{state: true, mechanism: :system_template})

      # page sets only the name, the mechanism comes from the org row
      assert {:error, cs} = TE.add(ap, :duplicate, %{template_ref: "dup"})
      assert {:template_ref, "template dup not found in the instance org"} in errors(cs)

      insert_template(instance, "dup")
      assert {:ok, _} = TE.add(ap, :duplicate, %{template_ref: "dup"})
    end

    test "external_queue has no template to check", %{org: org} do
      assert {:ok, _} =
               TE.add(org, :supporter_confirm, %{state: true, mechanism: :external_queue})
    end

    test "not checked when nothing template-related changes", %{org: org} do
      # stored before the check existed / template deleted later
      te = set!(org, :thank_you, %{template_ref: "gone"})
      assert {:ok, %TE{state: true}} = TE.update(te, %{state: true})
    end
  end

  describe "chain_all/1" do
    test "every role along the chain, grouped by role, most specific first", %{
      org: org,
      campaign: campaign,
      ap: ap
    } do
      set!(org, :thank_you, %{state: true})
      set!(ap, :thank_you, %{template_ref: "ty"})
      set!(campaign, :supporter_confirm, %{state: true})
      set!(Factory.insert(:org), :thank_you, %{state: true})

      assert [
               {:supporter_confirm, :campaign},
               {:thank_you, :action_page},
               {:thank_you, :org}
             ] == Enum.map(TE.chain_all(ap), &{&1.role, TE.level(&1)})

      assert [{:thank_you, :org}] == Enum.map(TE.chain_all(org), &{&1.role, TE.level(&1)})
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
        |> TE.changeset(%{state: true})

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
          |> TE.changeset(%{state: true})
          |> Repo.insert()
        end

        assert {:ok, _} = insert.()
        assert {:error, cs} = insert.()
        assert {:role, "is already set at this scope"} in errors(cs)
      end
    end

    test "rows are deleted with their scope", %{org: org, campaign: campaign, ap: ap} do
      set!(ap, :thank_you, %{state: true})
      Repo.delete!(ap)
      assert TE.get(ap, :thank_you) == nil

      set!(campaign, :thank_you, %{state: true})
      Repo.delete!(campaign)
      assert TE.get(campaign, :thank_you) == nil

      assert %TE{} = set!(org, :thank_you, %{state: true})
    end
  end
end
