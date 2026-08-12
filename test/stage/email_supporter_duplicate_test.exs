defmodule ProcaWeb.Stage.EmailSupporterDuplicateTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  import Proca.StoryFactory, only: [green_story: 0]
  alias Proca.{Factory, Repo}

  use Proca.TestEmailBackend

  setup do
    %{org: org, campaign: campaign, ap: ap} = green_story()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "thank_you_template",
      locale: "en",
      subject: "Thank you",
      html: "Thanks for signing!"
    })
    |> Repo.insert!()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "duplicate_template",
      locale: "en",
      subject: "You already signed!",
      html: "You have already taken this action."
    })
    |> Repo.insert!()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "confirm_template",
      locale: "en",
      subject: "Please confirm your opt-in",
      html: "Click {{confirm_link}} to confirm."
    })
    |> Repo.insert!()

    %{org: org, campaign: campaign, ap: ap}
  end

  describe "duplicate emails" do
    test "sends duplicate email when supporter is a dupe and duplicate_template is set", %{
      ap: action_page
    } do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)

      Repo.update!(Ecto.Changeset.change(action.supporter, dupe_rank: 1))

      action_data = Proca.Stage.Support.action_data(action)

      Proca.Stage.EmailSupporter.handle_batch(
        :duplicate,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)

      assert email.subject == "You already signed!"
      assert email.to == [{action.supporter.first_name, action.supporter.email}]
    end

    test "sends thank you when dupe but no duplicate_template set", %{ap: action_page} do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{thank_you_template: "thank_you_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action.supporter, dupe_rank: 1))

      action_data = Proca.Stage.Support.action_data(action)

      Proca.Stage.EmailSupporter.handle_batch(
        :thank_you,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Thank you"
    end

    test "send_duplicate? returns true when action has processing_status repeat and template is configured", %{
      ap: action_page
    } do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action, processing_status: :repeat))

      assert Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end

    test "send_duplicate? returns false when action is not repeat", %{ap: action_page} do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)

      refute Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end

    test "send_duplicate? returns false when duplicate_template is not set", %{ap: action_page} do
      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action, processing_status: :repeat))

      refute Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end
  end

  describe "repeat confirm fallback" do
    test "send_repeat_confirm? returns true when repeat, no duplicate_template, confirm template set",
         %{org: org, ap: action_page} do
      Repo.update!(Proca.Org.changeset(org, %{supporter_confirm_template: "confirm_template"}))
      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action, processing_status: :repeat))

      assert Proca.Stage.EmailSupporter.send_repeat_confirm?(action_page.id, action.id)
    end

    test "send_repeat_confirm? returns false when duplicate_template is set", %{
      org: org,
      ap: action_page
    } do
      Repo.update!(Proca.Org.changeset(org, %{supporter_confirm_template: "confirm_template"}))

      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action, processing_status: :repeat))

      refute Proca.Stage.EmailSupporter.send_repeat_confirm?(action_page.id, action.id)
    end

    test "send_repeat_confirm? returns false when action is not repeat", %{
      org: org,
      ap: action_page
    } do
      Repo.update!(Proca.Org.changeset(org, %{supporter_confirm_template: "confirm_template"}))
      action = Factory.insert(:action, action_page: action_page, with_consent: true)

      refute Proca.Stage.EmailSupporter.send_repeat_confirm?(action_page.id, action.id)
    end

    test "sends confirm email with confirm link for repeat action when no duplicate_template", %{
      org: org,
      ap: action_page
    } do
      Repo.update!(Proca.Org.changeset(org, %{supporter_confirm_template: "confirm_template"}))
      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action, processing_status: :repeat))

      action_data = Proca.Stage.Support.action_data(action)

      Proca.Stage.EmailSupporter.handle_batch(
        :supporter_confirm,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      assert email.subject == "Please confirm your opt-in"
      assert email.to == [{action.supporter.first_name, action.supporter.email}]
    end
  end
end
