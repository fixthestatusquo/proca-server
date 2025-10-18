defmodule Proca.Server.MTTSchedulerTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Repo
  alias Proca.Server.{MTTScheduler, MTTContext}

  import Proca.StoryFactory, only: [mtt_story: 0]

  @one_hour_ms 59 * 60 * 1000
  @base_for_4 div(@one_hour_ms, max(4 - 1, 1)) # messages_count = 4
  @base_for_5 div(@one_hour_ms, max(5 - 1, 1)) # messages_count = 5

  setup do
    %{
      targets: [target, _, target_live | _],
      messages_test: messages_test
    } = mtt_story()

    MTTContext.dupe_rank()

    max_emails = MTTContext.max_emails_per_hour(target.campaign)

    %{target: target, target_live: target_live, max_emails: max_emails, messages_test: messages_test}
  end

  describe "MTTScheduler" do
    test "Check test emails properly processed", %{target: target, messages_test: messages_test} do
      {target_id, count} = MTTContext.process_test_mails(target)

      assert target_id == target.id
      assert count == Enum.count(messages_test)

      # check for pending test messages after processing
      pending_messages = MTTContext.get_pending_test_messages(target_id)

      assert Enum.count(pending_messages) == 0
    end

    test "Delivering messages", %{target_live: target} do
      max_emails = MTTContext.max_emails_per_hour(target.campaign)

      message =
        MTTContext.get_pending_messages(target.id, max_emails)
        |> List.first()

      assert :ok == MTTContext.deliver_message(target, message)

      message = Repo.get(Proca.Action.Message, message.id)

      assert true == message.sent
    end

    test "check that after sending there're no pending messages", %{target: target, max_emails: max_emails} do
      # pending_messages before sending
      pending_messages_count = MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

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
      assert MTTScheduler.calc_interval(1, true, 0) == 10
      assert MTTScheduler.calc_interval(0, false, 0) == 10
    end
  end
end
