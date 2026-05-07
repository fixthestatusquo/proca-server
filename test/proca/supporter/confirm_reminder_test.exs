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

  @old_inserted_at ~U[2024-01-01 00:00:00Z]

  setup do
    # Reuse the testmail service started by TestEmailBackend setup
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
          supporter_confirm_template: "supporter_confirm"
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

  defp age_supporter(action) do
    Repo.update_all(
      from(s in Supporter, where: s.id == ^action.supporter_id),
      set: [inserted_at: @old_inserted_at]
    )
  end

  defp fetch_supporter(action) do
    Repo.get!(Supporter, action.supporter_id)
  end

  describe "ConfirmReminder.run/0" do
    test "sends reminder and increments reminder_count for overdue confirming supporter", %{
      ap: ap
    } do
      action = insert_confirming_action(ap)
      age_supporter(action)

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 1
      assert supporter.reminder_sent_at != nil

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Please confirm your action"
    end

    test "reminder confirm link contains ?reminder=1", %{ap: ap} do
      action = insert_confirming_action(ap)
      age_supporter(action)

      ConfirmReminder.run()

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.html_body =~ "reminder=1"
    end

    test "does not send reminder for supporter inserted recently", %{ap: ap} do
      action = insert_confirming_action(ap)

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 0
      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send second reminder if max_count already reached", %{ap: ap, org: org} do
      Repo.update!(change(org, config: %{"reminder" => %{"max_count" => 1}}))

      action = insert_confirming_action(ap)
      age_supporter(action)

      Repo.update_all(
        from(s in Supporter, where: s.id == ^action.supporter_id),
        set: [reminder_count: 1]
      )

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 1
      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "does not send reminder if org has supporter_confirm disabled", %{ap: ap, org: org} do
      Repo.update!(change(org, supporter_confirm: false))

      action = insert_confirming_action(ap)
      age_supporter(action)

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 0
    end

    test "does not send reminder for already accepted supporter", %{ap: ap} do
      action =
        Factory.insert(:action, action_page: ap, with_consent: true)
        |> Repo.preload(:supporter)

      age_supporter(action)

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 0
      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end

    test "respects per-org delay_days config", %{ap: ap, org: org} do
      Repo.update!(change(org, config: %{"reminder" => %{"delay_days" => 5}}))

      action = insert_confirming_action(ap)

      Repo.update_all(
        from(s in Supporter, where: s.id == ^action.supporter_id),
        set: [inserted_at: DateTime.add(DateTime.utc_now(), -2 * 86400, :second)]
      )

      ConfirmReminder.run()

      supporter = fetch_supporter(action)
      assert supporter.reminder_count == 0
      assert TestEmailBackend.mailbox(action.supporter.email) == []
    end
  end
end
