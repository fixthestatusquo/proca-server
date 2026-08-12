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

  @old_timestamp ~U[2024-01-01 00:00:00Z]

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
    Repo.update_all(
      from(a in Action, where: a.id == ^action.id),
      set: [updated_at: @old_timestamp]
    )
  end

  defp expire_action(action) do
    Repo.update_all(
      from(a in Action, where: a.id == ^action.id),
      set: [inserted_at: @old_timestamp, updated_at: @old_timestamp]
    )
  end

  defp fetch_supporter(action) do
    Repo.get!(Supporter, action.supporter_id)
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

    test "touches action updated_at after sending so next reminder is spaced", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      before_run = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      ConfirmReminder.run()

      updated = Repo.get!(Action, action.id)
      assert NaiveDateTime.compare(updated.updated_at, before_run) != :lt
    end

    test "does not send reminder for action updated recently", %{ap: ap} do
      action = insert_confirming_action(ap)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not re-send reminder immediately after first send", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_action(action)

      # First run sends, touching updated_at to now
      ConfirmReminder.run()
      # Second run should not send since updated_at is now fresh
      ConfirmReminder.run()

      assert length(TestEmailBackend.mailbox(action.supporter.email)) == 1
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

    test "respects per-org delay_days config", %{ap: ap, org: org} do
      Repo.update!(change(org, config: %{"reminder" => %{"enabled" => true, "delay_days" => 5}}))

      action = insert_confirming_action(ap)

      Repo.update_all(
        from(a in Action, where: a.id == ^action.id),
        set: [updated_at: DateTime.add(DateTime.utc_now(), -2 * 86400, :second)]
      )

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

    test "does not send reminder when reminder.enabled is not set in config", %{ap: ap, org: org} do
      Repo.update!(change(org, config: %{}))

      action = insert_confirming_action(ap)
      age_action(action)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send reminder when action is outside max_count window", %{ap: ap, org: org} do
      Repo.update!(
        change(org, config: %{"reminder" => %{"enabled" => true, "delay_days" => 1, "max_count" => 2}})
      )

      action = insert_confirming_action(ap)
      # inserted_at older than max_count * delay_days (2 days), so window is exhausted
      expire_action(action)

      ConfirmReminder.run()

      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end
  end
end
