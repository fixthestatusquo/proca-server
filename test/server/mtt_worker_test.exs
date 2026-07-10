defmodule Proca.Server.MTTWorkerTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  import Proca.StoryFactory, only: [green_story: 0]
  import Ecto.Query

  alias Proca.Repo
  alias Proca.Factory

  alias Proca.Server.MTTWorker
  alias Proca.Server.MTTContext
  alias Proca.Action.Message

  use Proca.TestEmailBackend
  use Proca.TestProcessing

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

    test "selection filters cannot be bypassed by dupe rank", %{
      ap: ap,
      targets: [target | _]
    } do
      valid_action =
        Factory.insert(:action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted,
          testing: false
        )

      valid = Factory.insert(:message, action: valid_action, target: target)
      sent = Factory.insert(:message, action: valid_action, target: target, sent: true)

      test_action =
        Factory.insert(:action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted,
          testing: true
        )

      testing = Factory.insert(:message, action: test_action, target: target)

      pending_action =
        Factory.insert(:action,
          action_page: ap,
          processing_status: :new,
          supporter_processing_status: :new,
          testing: false
        )

      undelivered = Factory.insert(:message, action: pending_action, target: target)

      Repo.update_all(
        from(m in Message, where: m.id in ^[valid.id, sent.id, testing.id, undelivered.id]),
        set: [dupe_rank: 0]
      )

      selected_ids =
        Message.select_by_targets([target.id], false, false)
        |> select([m], m.id)
        |> Repo.all()

      assert valid.id in selected_ids
      refute sent.id in selected_ids
      refute testing.id in selected_ids
      refute undelivered.id in selected_ids
    end
  end

  def move_schedule(%{id: id}, past_mins, future_mins) do
    now = DateTime.utc_now()
    start_at = DateTime.add(now, -60 * past_mins, :second)
    end_at = DateTime.add(now, 60 * future_mins, :second)

    Repo.update_all(from(mtt in Proca.MTT, where: mtt.campaign_id == ^id),
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

    test "live sending", %{campaign: c, target: %{id: tid, emails: [%{email: email}]}} do
      msgs = MTTWorker.get_emails_to_send([tid], {1, 1})

      Proca.Repo.update!(
        change(c.mtt, %{
          cc_contacts: ["first@domain.com", "second@domain.com"],
          cc_sender: true
        })
      )

      assert Enum.all?(msgs, fn %{
                                  action: %{
                                    supporter: %{
                                      last_name: ln
                                    }
                                  }
                                } ->
               ln != nil
             end)

      # deliver like Proca.Stage.MTT does when consuming the queue
      target = MTTContext.get_target(tid)
      Enum.each(msgs, &MTTContext.deliver_message(target, &1))

      te = Proca.TargetEmail.one(target_id: tid)
      assert te.email_status == :active

      mbox = Proca.TestEmailBackend.mailbox(email)

      assert length(mbox) == 20

      msg = List.first(mbox)
      assert length(msg.cc) == 3
      assert {"", "first@domain.com"} in msg.cc
      assert {"", "second@domain.com"} in msg.cc
      assert %{"Reply-To" => _} = msg.headers

      assert Enum.all?(msgs, &Proca.Repo.reload(&1).sent)
    end

    test "process_mtt_campaign fails closed when the org queue is unavailable", %{
      campaign: %{id: campaign_id},
      target: %{id: tid, emails: [%{email: email}]}
    } do
      move_schedule(%{id: campaign_id}, 29, 1)

      # fetch fresh so the preloads pick up the moved schedule
      c = Proca.Campaign.one(id: campaign_id)

      # No Pipes.Topology process runs for this fixture org. Publishing must
      # not fall back to direct provider delivery or mutate the DB.
      MTTWorker.process_mtt_campaign(c)

      assert Proca.TestEmailBackend.mailbox(email) == []

      assert Repo.aggregate(
               from(m in Message, where: m.target_id == ^tid and not m.sent),
               :count
             ) == 20
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

      process(action)

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

    MTTContext.deliver_message(MTTContext.get_target(t.id), msg)

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

    MTTContext.deliver_message(MTTContext.get_target(t.id), msg)

    [%{email: target_email}] = t.emails

    [email] = TestEmailBackend.mailbox(target_email)

    assert email.subject == msg.message_content.subject
    assert String.contains?(email.html_body, "Sent in Petition about")
    assert email.private[:custom_id] == "mtt:#{msg.id}"
  end

  describe "sending more emails than limit" do
    setup %{campaign: c, ap: ap, targets: [t1, t2 | _]} do
      actions =
        Factory.insert_list(200, :action,
          action_page: ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted
        )

      msgs1 = Enum.map(actions, &Factory.insert(:message, action: &1, target: t1))
      msgs2 = Enum.map(actions, &Factory.insert(:message, action: &1, target: t2))

      Proca.Server.MTT.dupe_rank()

      %{
        actions: actions,
        messages: List.flatten([msgs1, msgs2]),
        targets: [t1, t2]
      }
    end

    test "don't return more mtt than limit", %{
      actions: actions,
      campaign: c,
      targets: [%{id: tid1}, %{id: tid2}],
      messages: msgs
    } do
      emails = MTTWorker.get_emails_to_send([tid1, tid2], {700, 700})
      assert length(emails) == 99
    end
  end
end
