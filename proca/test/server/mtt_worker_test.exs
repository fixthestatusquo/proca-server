defmodule Proca.Server.MTTWorkerTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [green_story: 0]
  alias Proca.Factory

  alias Proca.Server.MTTWorker
  alias Proca.Action.Message

  use Proca.TestEmailBackend

  setup do
    green_story()
  end

  test "10 minutes is 3 cycles of 3 minutes", %{campaign: c} do
    assert MTTWorker.calculate_cycles(c) == {0, 3}
  end

  test "We are in sending window", %{campaign: c} do
    assert MTTWorker.within_sending_window(c)
  end

  # describe "storing contact fields in supporter" do
  #   test "last_name", %{campaign: c} do
  #   end
  # end

  describe "selecting targets to send" do
    setup %{campaign: c, ap: ap, targets: ts} do
      action1 =
        Factory.insert(:action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted,
          testing: true
        )

      action2 =
        Factory.insert(:action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted
        )

      {t1, t2} = Enum.split(ts, 3)

      msg1 = Enum.map(t1, &Factory.insert(:message, action: action1, target: &1))
      msg2 = Enum.map(t2, &Factory.insert(:message, action: action2, target: &1))

      %{
        test_messages: msg1,
        live_messages: msg2
      }
    end

    test "return all testing mtts at once", %{campaign: c, ap: ap, targets: ts} do
      tids = MTTWorker.get_sendable_target_ids(c)
      assert length(tids) == 10

      emails = Proca.Repo.all(MTTWorker.query_test_emails_to_delete())
      assert length(emails) == 0

      emails = MTTWorker.get_test_emails_to_send()
      assert length(emails) == 3

      # Before dupe rank was run:
      emails = MTTWorker.get_emails_to_send(tids, {700, 700})
      assert length(emails) == 0

      assert {:ok, _} = Proca.Server.MTT.dupe_rank()

      emails = MTTWorker.get_emails_to_send(tids, {1, 700})
      assert length(emails) == 0

      emails = MTTWorker.get_emails_to_send(tids, {700, 700})
      assert length(emails) == 7

      # we have 3 test emails and 7 live emails (one per target), so at 699 we still do not send that one i guess?
      emails = MTTWorker.get_emails_to_send(tids, {699, 700})
      assert length(emails) == 0
    end
  end

  def move_schedule(%{id: id}, past_mins, future_mins) do
    import Ecto.Query
    import Proca.Repo

    now = DateTime.utc_now()
    start_at = DateTime.add(now, -60 * past_mins, :second)
    end_at = DateTime.add(now, 60 * future_mins, :second)

    update_all(from(mtt in Proca.MTT, where: mtt.campaign_id == ^id),
      set: [start_at: start_at, end_at: end_at]
    )

    Proca.Campaign.one(id: id, preload: [:mtt])
    |> MTTWorker.calculate_cycles()
  end

  describe "scheduling messages for one target" do
    setup %{campaign: c, ap: ap, targets: [t1 | _]} do
      actions =
        Factory.insert_list(20, :action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted
        )

      msgs = Enum.map(actions, &Factory.insert(:message, action: &1, target: t1))

      Proca.Server.MTT.dupe_rank()

      %{
        actions: actions,
        messages: msgs,
        target: t1
      }
    end

    test "Test sending on schedule", %{actions: actions, campaign: c, target: %{id: tid}} do
      # cycle is every 3 mins, so have 10 cycles
      # 0..2.59 - send 2
      # 3..5.59 - send 2
      # 6..8.59 - send 2
      # 9..11.59 ..
      # 12..14.59
      # last cycle: 27:00->29.59
      count = length(actions)

      cycle = move_schedule(c, 1, 29)
      emails = MTTWorker.get_emails_to_send([tid], cycle)
      assert length(emails) == 2
      Message.mark_all(emails, :sent)

      # in second cycle
      cycle = move_schedule(c, 5, 25)
      emails = MTTWorker.get_emails_to_send([tid], cycle)
      assert length(emails) == 2
      Message.mark_all(emails, :sent)

      # in second cycle
      cycle = move_schedule(c, 29, 1)
      emails = MTTWorker.get_emails_to_send([tid], cycle)
      # all remining, because we skipped to last cycle
      assert length(emails) == count - 4
      Message.mark_all(emails, :sent)
    end

    test "test sending", %{campaign: c, target: %{id: tid, emails: [%{email: email}]}} do
      import Ecto.Query
      Proca.Repo.update_all(from(a in Proca.Action), set: [testing: true])

      test_email = "testemail@proca.app"
      c = %{c | mtt: Proca.Repo.update!(change(c.mtt, %{test_email: test_email}))}

      MTTWorker.process_mtt_test_mails()

      mbox = Proca.TestEmailBackend.mailbox(test_email)

      assert length(mbox) == 20
    end

    test "live sending", %{campaign: c, target: %{id: tid, emails: [%{email: email}]}} do
      msgs = MTTWorker.get_emails_to_send([tid], {1, 1})

      assert Enum.all?(msgs, fn %{
                                  action: %{
                                    supporter: %{
                                      last_name: ln
                                    }
                                  }
                                } ->
               ln != nil
             end)

      MTTWorker.send_emails(c, msgs)
      mbox = Proca.TestEmailBackend.mailbox(email)

      assert length(mbox) == 20
    end
  end

  test "preserving email and last name for MTTs", %{campaign: c, org: org} do
    assert Proca.Pipes.Connection.is_connected?()

    preview_ap = Factory.insert(:action_page, campaign: c, org: org, live: false)
    live_ap = Factory.insert(:action_page, campaign: c, org: org, live: true)

    test_for = fn ap ->
      supporter = Factory.insert(:basic_data_pl_supporter_with_contact, action_page: ap)

      assert supporter.email != nil
      assert supporter.last_name != nil

      action = Factory.insert(:action, supporter: supporter)

      Proca.Server.Processing.process(action)

      action = Proca.Repo.reload(action)
      assert action.processing_status == :delivered

      supporter = Proca.Repo.reload(supporter)
      assert supporter.email != nil
      assert supporter.last_name != nil
    end

    test_for.(preview_ap)
    test_for.(live_ap)
  end

  test "sending without template", %{campaign: c, targets: [t | _]} do
    msg = Factory.insert(:message, target: t)

    MTTWorker.send_emails(c, [msg])

    [%{email: target_email}] = t.emails

    [email] = TestEmailBackend.mailbox(target_email)

    assert String.starts_with?(email.html_body, "<p>MTT text body to #{t.name}")
    assert String.starts_with?(email.subject, "MTT Subject to #{t.name}")
  end

  test "sending with local template", %{org: org, campaign: c, ap: page, targets: [t | _]} do
    import Proca.Repo

    msg = Factory.insert(:message, target: t)

    template =
      insert!(
        Proca.Service.EmailTemplate.changeset(%{
          org: org,
          name: "local_mtt",
          locale: "en",
          subject: "{{subject}}",
          html: """
          {{{body}}}

          <p>Sent in {{campaign.title}} campaign</p>
          """
        })
      )

    update!(Proca.MTT.changeset(c.mtt, %{message_template: template.name}))

    c = Proca.Campaign.one(id: c.id, preload: [:mtt, :org])

    MTTWorker.send_emails(c, [msg])

    [%{email: target_email}] = t.emails

    [email] = TestEmailBackend.mailbox(target_email)

    assert email.subject == msg.message_content.subject
    assert String.contains?(email.html_body, "Sent in Petition about")
    assert email.private[:custom_id] == "mtt:#{msg.id}"
  end
end
