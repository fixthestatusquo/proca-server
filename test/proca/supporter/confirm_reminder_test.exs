defmodule Proca.Supporter.ConfirmReminderTest do
  use Proca.DataCase, async: false
  @moduletag start: [:stats]

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.{Factory, Repo}
  alias Proca.{Action, Supporter}
  alias Proca.Service.EmailTemplate
  alias Proca.Supporter.ConfirmReminder

  use Proca.TestEmailBackend

  setup do
    email_service = Proca.Service.one(name: :testmail)

    org =
      Factory.insert(:org,
        email_from: "test@example.org",
        email_backend_id: email_service.id
      )

    org =
      Repo.update!(
        change(org,
          supporter_confirm: true,
          supporter_confirm_template: "supporter_confirm",
          config: %{"reminder" => %{"enabled" => true}}
        )
      )

    EmailTemplate.changeset(%{
      org: org,
      name: "supporter_confirm",
      locale: "en",
      subject: "Please confirm your action",
      text: "Click to confirm",
      html: "<a href='{{confirmLink}}'>Confirm</a>"
    })
    |> Repo.insert!()

    campaign =
      Factory.insert(:campaign,
        org: org,
        name: "test_reminder_campaign_#{System.unique_integer()}",
        title: "Test Campaign"
      )

    ap =
      Factory.insert(:action_page,
        org: org,
        campaign: campaign,
        name: "test_reminder_#{System.unique_integer()}/en",
        locale: "en"
      )

    %{org: org, campaign: campaign, ap: ap}
  end

  defp insert_confirming_action(ap) do
    action = Factory.insert(:action, action_page: ap, with_consent: true)
    Repo.update!(change(action.supporter, processing_status: :confirming))
    Repo.get!(Action, action.id) |> Repo.preload(:supporter)
  end

  defp age_action(action) do
    set_action_age_days(action, 3)
  end

  defp set_action_age_days(action, days) do
    ts = DateTime.add(DateTime.utc_now(), -days * 86400, :second)

    Repo.update_all(
      from(a in Action, where: a.id == ^action.id),
      set: [inserted_at: ts]
    )
  end

  describe "ConfirmReminder.run/0" do
    test "sends reminder when action is overdue", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Please confirm your action"
    end

    test "reminder confirm link contains ?reminder=1", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.html_body =~ "reminder=1"
    end

    test "increments reminder_count after sending", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      updated = Repo.get!(Action, action.id)
      assert updated.reminder_count == 1
    end

    test "does not send reminder for action inserted recently", %{ap: ap} do
      action = insert_confirming_action(ap)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not re-send reminder immediately after first send", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()
      # reminder_count is now 1; inserted_at is old but only 2 days elapsed since
      # signup, not 5, so the second reminder slot is not yet due
      ConfirmReminder.run()

      assert length(TestEmailBackend.mailbox(action.supporter.email)) == 1
    end

    test "sends second reminder when action reaches second delay threshold", %{ap: ap, org: org} do
      Repo.update!(
        change(org,
          config: %{"reminder" => %{"enabled" => true, "reminder_delays_days" => [2, 5]}}
        )
      )

      action = insert_confirming_action(ap)
      # Simulate: 6 days since signup, first reminder already sent
      set_action_age_days(action, 6)

      Repo.update_all(
        from(a in Action, where: a.id == ^action.id),
        set: [reminder_count: 1]
      )

      ConfirmReminder.run()

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Please confirm your action"

      updated = Repo.get!(Action, action.id)
      assert updated.reminder_count == 2
    end

    test "does not send more than the configured number of reminders", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      # Simulate both reminders already sent
      Repo.update_all(
        from(a in Action, where: a.id == ^action.id),
        set: [reminder_count: 2]
      )

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send reminder for action older than max_age_days", %{ap: ap, org: org} do
      Repo.update!(
        change(org,
          config: %{"reminder" => %{"enabled" => true, "max_age_days" => 7}}
        )
      )

      action = insert_confirming_action(ap)
      # 10 days old — beyond the 7-day max age
      set_action_age_days(action, 10)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send reminder if org has supporter_confirm disabled", %{ap: ap, org: org} do
      Repo.update!(change(org, supporter_confirm: false))

      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send reminder for already accepted supporter", %{ap: ap} do
      action =
        Factory.insert(:action, action_page: ap, with_consent: true)
        |> Repo.preload(:supporter)

      age_action(action)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "respects per-org reminder_delays_days config", %{ap: ap, org: org} do
      Repo.update!(
        change(org,
          config: %{"reminder" => %{"enabled" => true, "reminder_delays_days" => [5, 10]}}
        )
      )

      action = insert_confirming_action(ap)
      # 3 days old — not yet past the first 5-day delay
      set_action_age_days(action, 3)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "sends reminder when campaign has supporter_confirm (org does not)", %{
      org: org,
      campaign: campaign
    } do
      Repo.update!(change(org, supporter_confirm: false))
      Repo.update!(change(campaign, supporter_confirm: true))

      ap =
        Factory.insert(:action_page,
          org: org,
          campaign: campaign,
          name: "test_campaign_confirm_#{System.unique_integer()}/en",
          locale: "en"
        )

      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Please confirm your action"
    end
  end
end
