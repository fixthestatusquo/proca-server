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

    test "send_duplicate? returns true when action is dupe and template is configured", %{
      ap: action_page
    } do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action.supporter, dupe_rank: 1))

      assert Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end

    test "send_duplicate? returns false when action is not a dupe", %{ap: action_page} do
      action_page =
        Repo.update!(
          Proca.ActionPage.changeset(action_page, %{duplicate_template: "duplicate_template"})
        )

      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action.supporter, dupe_rank: 0))

      refute Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end

    test "send_duplicate? returns false when duplicate_template is not set", %{ap: action_page} do
      action = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(action.supporter, dupe_rank: 1))

      refute Proca.Stage.EmailSupporter.send_duplicate?(action_page.id, action.id)
    end
  end

  describe "dupe_same_page" do
    test "naive_rank sets dupe_same_page true when previous accepted supporter is from same action page", %{
      ap: action_page,
      campaign: campaign
    } do
      existing = Factory.insert(:action, action_page: action_page, with_consent: true)
      Repo.update!(Ecto.Changeset.change(existing.supporter, processing_status: :accepted))

      ch =
        Ecto.Changeset.change(%Proca.Supporter{}, %{
          fingerprint: existing.supporter.fingerprint,
          campaign_id: campaign.id,
          action_page_id: action_page.id
        })

      result = Proca.Supporter.naive_rank(ch)

      assert Ecto.Changeset.get_change(result, :dupe_rank) == 1
      assert Ecto.Changeset.get_change(result, :dupe_same_page) == true
    end

    test "naive_rank sets dupe_same_page false when previous accepted supporter is from different action page", %{
      org: org,
      campaign: campaign,
      ap: action_page
    } do
      other_ap = Factory.insert(:action_page, org: org, campaign: campaign, name: "mtt/fr", locale: "fr")

      existing = Factory.insert(:action, action_page: other_ap, with_consent: true)
      Repo.update!(Ecto.Changeset.change(existing.supporter, processing_status: :accepted))

      ch =
        Ecto.Changeset.change(%Proca.Supporter{}, %{
          fingerprint: existing.supporter.fingerprint,
          campaign_id: campaign.id,
          action_page_id: action_page.id
        })

      result = Proca.Supporter.naive_rank(ch)

      assert Ecto.Changeset.get_change(result, :dupe_rank) == 1
      assert Ecto.Changeset.get_change(result, :dupe_same_page) == false
    end

    test "naive_rank leaves dupe_same_page nil when not a dupe", %{
      ap: action_page,
      campaign: campaign
    } do
      fingerprint = :crypto.strong_rand_bytes(32)

      ch =
        Ecto.Changeset.change(%Proca.Supporter{}, %{
          fingerprint: fingerprint,
          campaign_id: campaign.id,
          action_page_id: action_page.id
        })

      result = Proca.Supporter.naive_rank(ch)

      assert Ecto.Changeset.get_change(result, :dupe_rank) == 0
      assert Ecto.Changeset.get_change(result, :dupe_same_page) == nil
    end
  end
end
