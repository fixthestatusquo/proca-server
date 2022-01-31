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
      action1 = Factory.insert(:action, action_page: ap, processing_status: :testing)
      action2 = Factory.insert(:action, action_page: ap, processing_status: :delivered)

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

      emails = MTTWorker.get_test_emails_to_send()
      assert length(emails) == 3

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
      actions = Factory.insert_list(20, :action, action_page: ap, processing_status: :delivered)
      msgs = Enum.map(actions, &Factory.insert(:message, action: &1, target: t1))

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
      Proca.Repo.update_all(from(a in Proca.Action), set: [processing_status: :testing])

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
end
