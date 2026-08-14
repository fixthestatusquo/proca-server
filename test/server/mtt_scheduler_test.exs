defmodule Proca.Server.MTTSchedulerTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Repo
  alias Proca.Server.{MTTScheduler, MTTContext}

  import Proca.StoryFactory, only: [mtt_story: 0]

  @one_hour_ms 55 * 60 * 1000
  @base_for_4 div(@one_hour_ms, max(4 - 1, 1))
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
    test "processes test emails", %{
      targets: [%{emails: [%{email: test_email}]} = target | _],
      action: action
    } do
      Repo.update!(Ecto.Changeset.change(target.campaign.mtt, %{test_email: test_email}))

      MTTContext.deliver_test_mails(action.id)

      mbox = Proca.TestEmailBackend.mailbox(action.supporter.email)

      assert length(mbox) == 1

      msg = List.first(mbox)
      assert String.starts_with?(msg.subject, "[TEST]")
      assert msg.cc == [{"", test_email}]

      import Ecto.Query, only: [from: 2]

      refute Repo.exists?(
               from(m in Proca.Action.Message,
                 join: a in assoc(m, :action),
                 where: a.id == ^action.id and not m.sent
               )
             )
    end

    test "delivers live messages", %{
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

      pending_messages_count =
        MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      {:ok, pid} = MTTScheduler.start_link(target, max_emails)

      state = :sys.get_state(pid)

      send(pid, {:send_message})

      :timer.sleep(2000)

      # The scheduler exhausts its in-memory dispatch list, but because the
      # fixture org has no queue topology, DB messages remain available for a
      # later scheduler run. There is deliberately no direct-send fallback.
      messages_count = MTTContext.get_pending_messages(target.id, max_emails) |> Enum.count()

      assert state.count == pending_messages_count
      assert messages_count == pending_messages_count
    end
  end

  describe "calc_interval/3" do
    test "uses simple division for the final even message" do
      assert MTTScheduler.calc_interval(4, true, 1) == @base_for_4
    end

    test "applies jitter with a 1s minimum" do
      base = @base_for_5
      jitter_amount = div(base, 4)
      expected_plus = max(base + jitter_amount, 1000)
      expected_minus = max(base - jitter_amount, 1000)

      assert MTTScheduler.calc_interval(5, true, 3) == expected_plus
      assert MTTScheduler.calc_interval(5, false, 3) == expected_minus
    end

    test "falls back to a short interval when scheduling does not apply" do
      assert MTTScheduler.calc_interval(1, true, 0) == 1000
      assert MTTScheduler.calc_interval(0, false, 0) == 1000
    end
  end
end
