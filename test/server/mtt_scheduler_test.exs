defmodule Proca.Server.MTTSchedulerTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Repo
  alias Proca.Server.{MTTScheduler, MTTContext}

  import Proca.StoryFactory, only: [mtt_story: 0]

  @one_hour_ms 55 * 60 * 1000
  # messages_count = 4
  @base_for_4 div(@one_hour_ms, max(4 - 1, 1))
  # messages_count = 5
  @base_for_5 div(@one_hour_ms, max(5 - 1, 1))

  setup do
    %{
      targets: targets,
      messages_test: messages_test,
      messages_live: messages_live,
      action: action
    } = mtt_story()

    MTTContext.dupe_rank()

    %{
      targets: targets,
      messages_test: messages_test,
      messages_live: messages_live,
      action: action
    }
  end

  describe "MTTScheduler" do
    test "Check test emails properly processed", %{
      targets: [%{emails: [%{email: test_email}]} = target | _],
      messages_test: messages_test,
      action: action
    } do
      target =
        target
        |> Map.put(
          :campaign,
          target.campaign
          |> Map.put(
            :mtt,
            Repo.update!(Ecto.Changeset.change(target.campaign.mtt, %{test_email: test_email}))
          )
        )

      {target_id, count} = MTTContext.process_test_mails(target)

      assert target_id == target.id
      assert count == Enum.count(messages_test)

      mbox = Proca.TestEmailBackend.mailbox(action.supporter.email)

      # limit to one per locale!
      assert length(mbox) == 1
      msg = mbox |> List.first()

      assert String.starts_with?(msg.subject, "[TEST]")
      assert msg.cc == [{"", test_email}]

      # check for pending test messages after processing
      pending_messages = MTTContext.get_pending_test_messages(target_id)

      assert Enum.count(pending_messages) == 0
    end

    test "Delivering messages", %{
      targets: [_, _, %{emails: [%{email: email}]} = target | _],
      messages_live: messages_live
    } do
      max_emails = MTTContext.max_emails_per_hour(target.campaign)

      MTTContext.get_pending_messages(target.id, max_emails)
      |> Enum.each(fn message ->
        assert MTTContext.deliver_message(target, message) == :ok

        message = Repo.get(Proca.Action.Message, message.id)
        assert message.sent == true
      end)

      target_email = Proca.TargetEmail.one(target_id: target.id)
      assert target_email.email_status == :active

      mbox = Proca.TestEmailBackend.mailbox(email)

      assert Enum.count(mbox) == Enum.count(messages_live)

      msg = List.first(mbox)
      assert %{"Reply-To" => _} = msg.headers
    end

    test "check that after sending there're no pending messages", %{targets: [target | _]} do
      max_emails = MTTContext.max_emails_per_hour(target.campaign)

      # pending_messages before sending
      pending_messages_count =
        MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      {:ok, pid} = MTTScheduler.start_link(target, max_emails)

      # # Get initial state
      state = :sys.get_state(pid)

      send(pid, {:send_message})

      :timer.sleep(2000)

      # messages after sending
      messages_count = MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      assert state.count == pending_messages_count
      assert messages_count == 0
    end
  end

  describe "calc_interval/3" do
    test "even messages_count last element uses simple division" do
      assert MTTScheduler.calc_interval(4, true, 1) == @base_for_4
    end

    test "jitter applied (+/-25%) and minimum 1s enforced" do
      base = @base_for_5
      jitter_amount = div(base, 4)
      expected_plus = max(base + jitter_amount, 1000)
      expected_minus = max(base - jitter_amount, 1000)

      assert MTTScheduler.calc_interval(5, true, 3) == expected_plus
      assert MTTScheduler.calc_interval(5, false, 3) == expected_minus
    end

    test "fallback returns small default when not applicable" do
      assert MTTScheduler.calc_interval(1, true, 0) == 1000
      assert MTTScheduler.calc_interval(0, false, 0) == 1000
    end
  end
end
