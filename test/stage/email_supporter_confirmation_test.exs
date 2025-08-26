defmodule ProcaWeb.Stage.EmailSupporterConfirmationTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  import Proca.StoryFactory, only: [green_story: 0]
  alias Proca.{Factory, Repo}

  use Proca.TestEmailBackend
  use Proca.TestProcessing

  setup do
    %{
      org: org,
      campaign: campaign,
      ap: ap,
      targets: targets
    } = green_story()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "test_org_template",
      locale: "en",
      subject: "Test Org Confirmation",
      text: "Test Organization confirmation email on org level",
      html: """
      This is the email html body
      """
    })
    |> Repo.insert!()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "test_campaign_template",
      locale: "en",
      subject: "Test Campaign Confirmation",
      text: "Test Campaign confirmation email on campaign level",
      html: """
      This is the email html body
      """
    })
    |> Repo.insert!()

    Proca.Service.EmailTemplate.changeset(%{
      org: org,
      name: "mustache template",
      locale: "en",
      subject: "Hello {{firstName}}",
      html: """
      Hi, emailing you at {{email}}.

      You decided to {{#privacy}}{{#optIn}}subscribe{{/optIn}}{{^optIn}}unsubscribe{{/optIn}}{{/privacy}}
      """
    })
    |> Repo.insert!()

    %{
      org: org,
      campaign: campaign,
      ap: ap,
      targets: targets
    }
  end

  describe "supporter confirmation emails" do
    test "sends email using org template if campaign supporter_confirmation set to false and has no template", %{
      org: org, ap: action_page
    } do
      # This covers: org.confirm = true && campaign.confirm = false
      # Setup
      org = Repo.update!(Ecto.Changeset.change(org, supporter_confirm: true, supporter_confirm_template: "test_org_template"))

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      action_data = Proca.Stage.Support.action_data(action, :supporter_confirm)

      Proca.Stage.EmailSupporter.handle_batch(
        :supporter_confirm,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)

      # Assert
      assert email.subject == "Test Org Confirmation"
      assert email.text_body == "Test Organization confirmation email on org level"
      assert email.to == [{action.supporter.first_name, action.supporter.email}]
      assert email.from |> elem(0) == org.title
    end

    test "sends email using campaign template if it is set and if campaign haven't set supporter_confirmation send with org template", %{org: org, ap: action_page} do
      # This covers: org.confirm = true && campaign.confirm = true
      # Setup
      org = Repo.update!(Ecto.Changeset.change(org, supporter_confirm: true, supporter_confirm_template: "test_org_template"))

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      action_data = Proca.Stage.Support.action_data(action, :supporter_confirm)

      Proca.Stage.EmailSupporter.handle_batch(
        :supporter_confirm,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      campaign_with_supporter_confirm = Factory.insert(
        :campaign,
        org: org,
        name: "violet_campaign_with_confirmation",
        title: "Violets not Violence",
        supporter_confirm: true,
        supporter_confirm_template: "test_campaign_template"
      )

      action_page_with_confirmation =
        Factory.insert(:action_page, org: org, campaign: campaign_with_supporter_confirm, name: "violet_campaign_with_confirmation", locale: "en")

      action_with_confirmation = Factory.insert(:action, action_page: action_page_with_confirmation, with_consent: true)
      action_data_with_confirmation = Proca.Stage.Support.action_data(action_with_confirmation, :supporter_confirm)

      Proca.Stage.EmailSupporter.handle_batch(
        :supporter_confirm,
        [%Broadway.Message{data: action_data_with_confirmation, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page_with_confirmation.id},
        nil
      )

      [email_org] = TestEmailBackend.mailbox(action.supporter.email)

      [email_campaign] = TestEmailBackend.mailbox(action_with_confirmation.supporter.email)

      # Assert
      assert email_org.subject == "Test Org Confirmation"
      assert email_org.text_body == "Test Organization confirmation email on org level"
      assert email_org.to == [{action.supporter.first_name, action.supporter.email}]
      assert email_org.from |> elem(0) == org.title

      assert email_campaign.subject == "Test Campaign Confirmation"
      assert email_campaign.text_body == "Test Campaign confirmation email on campaign level"
      assert email_campaign.to == [{action_with_confirmation.supporter.first_name, action_with_confirmation.supporter.email}]
      assert email_campaign.from |> elem(0) == org.title
    end

    test "sends email using action page template if it is set", %{org: org, campaign: campaign, ap: action_page} do
      # This covers: org.confirm = false && campaign.confirm = true
      # Setup
      Repo.update!(Ecto.Changeset.change(campaign, supporter_confirm: true, supporter_confirm_template: "test_campaign_template"))

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      action_data = Proca.Stage.Support.action_data(action, :supporter_confirm)

      Proca.Stage.EmailSupporter.handle_batch(
        :supporter_confirm,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      campaign_org = Factory.insert(
        :campaign,
        org: org,
        name: "campaign_without_confirmation",
        title: "Without Confirmation"
      )

      action_page_org =
        Factory.insert(
          :action_page,
          org: org,
          campaign: campaign_org,
          name: "campaign_without_confirmation",
          locale: "en",
          thank_you_template: "mustache template"
        )

      action_org = Factory.insert(:action, action_page: action_page_org, with_consent: true)
      action_data_org = Proca.Stage.Support.action_data(action_org)

      Proca.Stage.EmailSupporter.handle_batch(
        :thank_you,
        [%Broadway.Message{data: action_data_org, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page_org.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)
      [email_org] = TestEmailBackend.mailbox(action_org.supporter.email)

      # Assert
      assert email.subject == "Test Campaign Confirmation"
      assert email.text_body == "Test Campaign confirmation email on campaign level"
      assert email.to == [{action.supporter.first_name, action.supporter.email}]
      assert email.from |> elem(0) == org.title

      assert email_org.subject == "Hello #{action_org.supporter.first_name}"
      assert email_org.to == [{action_org.supporter.first_name, action_org.supporter.email}]
      assert email_org.from |> elem(0) == org.title
      assert String.contains?(email_org.html_body, "You decided to subscribe")
    end

    test "does not send email if no template is configured", %{org: org, ap: action_page} do
      # This covers: org.confirm = false && campaign.confirm = false
      # Setup
      action_page = Repo.update!(Proca.ActionPage.changeset(action_page, %{thank_you_template: "mustache template"}))
      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      action_data = Proca.Stage.Support.action_data(action, :supporter_confirm)

      Proca.Stage.EmailSupporter.handle_batch(
        :thank_you,
        [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
        %Broadway.BatchInfo{batch_key: action_page.id},
        nil
      )

      [email] = TestEmailBackend.mailbox(action.supporter.email)

      assert email.subject == "Hello #{action.supporter.first_name}"
      assert email.to == [{action.supporter.first_name, action.supporter.email}]
      assert email.from |> elem(0) == org.title
      assert String.contains?(email.html_body, "You decided to subscribe")
    end
  end
end
