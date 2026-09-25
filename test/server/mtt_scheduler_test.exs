defmodule Proca.Server.MTTSchedulerTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Repo
  alias Proca.Server.{MTTScheduler, MTTContext}

  import Proca.StoryFactory, only: [mtt_story: 0]

  @send_window_ms 55 * 60 * 1000

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
      action: action
    } do
      Repo.update!(Ecto.Changeset.change(target.campaign.mtt, %{test_email: test_email}))

      MTTContext.deliver_test_mails(action.id)

      mbox = Proca.TestEmailBackend.mailbox(action.supporter.email)

      # limit to one per locale!
      assert length(mbox) == 1
      msg = mbox |> List.first()

      assert String.starts_with?(msg.subject, "[TEST]")
      assert msg.cc == [{"", test_email}]

      # all test messages of the action are marked sent
      import Ecto.Query, only: [from: 2]

      refute Repo.exists?(
               from(m in Proca.Action.Message,
                 join: a in assoc(m, :action),
                 where: a.id == ^action.id and not m.sent
               )
             )
    end

    test "Delivering messages", %{
      targets: [_, _, %{emails: [%{email: email}]} = target | _],
      messages_live: messages_live
    } do
      MTTContext.get_pending_messages(target.id, :all)
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

    test "queue outage leaves scheduled messages pending", %{targets: [target | _]} do
      max_emails = MTTContext.max_emails_per_hour(target.campaign)

      # pending_messages before sending
      pending_messages_count =
        MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      {:ok, pid} = MTTScheduler.start_link(target, max_emails)

      # # Get initial state
      state = :sys.get_state(pid)

      send(pid, {:send_message})

      :timer.sleep(2000)

      # The scheduler exhausts its in-memory dispatch list, but because the
      # fixture org has no queue topology, DB messages remain available for a
      # later scheduler run. There is deliberately no direct-send fallback.
      messages_count = MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      assert length(state.messages) == pending_messages_count
      assert messages_count == pending_messages_count
    end
  end

  describe "bucket_waits/2" do
    test "no messages, no waits" do
      assert MTTScheduler.bucket_waits(0, @send_window_ms) == []
    end

    test "consistent for every count: one wait per message, all positive" do
      for count <- 1..6 do
        waits = MTTScheduler.bucket_waits(count, @send_window_ms)
        assert length(waits) == count
        assert Enum.all?(waits, &(&1 > 0))
      end
    end

    test "each message lands inside its own bucket" do
      count = 6
      bucket = div(@send_window_ms, count)

      offsets =
        count
        |> MTTScheduler.bucket_waits(@send_window_ms)
        |> Enum.scan(&(&1 + &2))

      offsets
      |> Enum.with_index()
      |> Enum.each(fn {offset, i} ->
        assert offset >= i * bucket
        assert offset < (i + 1) * bucket
      end)
    end

    test "a lone message is scheduled somewhere in the whole window" do
      [wait] = MTTScheduler.bucket_waits(1, @send_window_ms)
      assert wait >= 0
      assert wait < @send_window_ms
    end
  end
end
