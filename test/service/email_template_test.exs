defmodule Proca.EmailTemplateTest do
  use Proca.DataCase
  @moduletag start: [:stats]
  use Proca.TestEmailBackend
  import Ecto.Changeset
  import Proca.Repo

  import Proca.StoryFactory, only: [violet_story: 0]

  alias Proca.Service.EmailTemplate

  setup do
    ctx = violet_story()
  end

  test "sending a thank you email with local template", %{org: org, ap: page} do
    page = update!(Proca.ActionPage.changeset(page, %{thank_you_template: "mustache template"}))
    action = Factory.insert(:action, action_page: page, supporter_processing_status: :accepted)

    action_data = Proca.Stage.Support.action_data(action)

    Proca.Stage.EmailSupporter.handle_batch(
      :thank_you,
      [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
      %Broadway.BatchInfo{batch_key: page.id},
      nil
    )

    [email] = TestEmailBackend.mailbox(action.supporter.email)

    assert email.subject == "Hello #{action.supporter.first_name}"
    assert email.to == [{action.supporter.first_name, action.supporter.email}]

    assert email.from == {org.title, "contact@violet.org"}
    assert String.contains?(email.html_body, "You decided to subscribe")
  end

  test "sending a thank you email with remote template", %{org: org, ap: page} do
    org = Proca.Repo.preload(org, [:email_backend])
    page = update!(Proca.ActionPage.changeset(page, %{thank_you_template: "thank_you"}))
    action = Factory.insert(:action, action_page: page, supporter_processing_status: :accepted)

    action_data = Proca.Stage.Support.action_data(action)

    Proca.Stage.EmailSupporter.handle_batch(
      :thank_you,
      [%Broadway.Message{data: action_data, acknowledger: Broadway.NoopAcknowledger}],
      %Broadway.BatchInfo{batch_key: page.id},
      nil
    )

    [email] = TestEmailBackend.mailbox(action.supporter.email)

    assert email.provider_options[:template_ref] == "ref:thankyouemail"
    assert email.assigns["campaignTitle"] == "Violets not Violence"
  end
end
