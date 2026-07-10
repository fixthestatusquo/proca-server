defmodule Proca.Stage.MTTStageTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Repo
  alias Proca.Server.MTTContext
  alias Proca.Stage.MTT
  alias Proca.Stage.MTTTest, as: MTTTestStage
  alias Proca.Pipes.Topology

  import Proca.StoryFactory, only: [mtt_story: 0]

  setup do
    %{targets: targets, action: action} = mtt_story()

    MTTContext.dupe_rank()

    # 3rd target belongs to the live (non-test) campaign, like in MTTSchedulerTest
    [first_target, _, target | _] = targets

    %{target: target, action: action, first_target: first_target}
  end

  describe "deliver/2" do
    test "sends the email, marks message sent, and ignores re-delivery", %{
      target: %{emails: [%{email: email}]} = target
    } do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      assert MTT.deliver(msg.id, target.id) == :ok
      assert Repo.get(Proca.Action.Message, msg.id).sent
      assert [_] = Proca.TestEmailBackend.mailbox(email)

      # a re-delivered queue message must not send twice
      assert MTT.deliver(msg.id, target.id) == :ignore
      assert [_] = Proca.TestEmailBackend.mailbox(email)
    end

    test "ignores unknown message or target", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      assert MTT.deliver(-1, target.id) == :ignore
      assert MTT.deliver(msg.id, Ecto.UUID.generate()) == {:discard, :target_mismatch}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end
  end

  describe "handle_message/3" do
    test "delivers on valid payload", %{target: %{emails: [%{email: email}]} = target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      {:ok, payload} = JSON.encode(%{messageId: msg.id, targetId: target.id})

      message = %Broadway.Message{
        data: payload,
        acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
      }

      result = MTT.handle_message(:default, message, nil)

      assert result.status == :ok
      assert Repo.get(Proca.Action.Message, msg.id).sent
      assert [_] = Proca.TestEmailBackend.mailbox(email)
    end

    test "sends test emails for a confirmed testing action and marks them sent", %{
      action: action,
      first_target: %{emails: [%{email: test_email}]} = first_target
    } do
      Repo.update!(Ecto.Changeset.change(first_target.campaign.mtt, %{test_email: test_email}))

      {:ok, payload} = JSON.encode(%{actionId: action.id, stage: "deliver", testing: true})

      message = %Broadway.Message{
        data: payload,
        acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
      }

      result = MTTTestStage.handle_message(:default, message, nil)

      assert result.status == :ok

      # one email per locale, to the supporter who tests
      mbox = Proca.TestEmailBackend.mailbox(action.supporter.email)
      assert [msg] = mbox
      assert String.starts_with?(msg.subject, "[TEST]")

      # re-delivery does not send again: all the action's messages are sent
      assert MTTContext.deliver_test_mails(action.id) == :ok
      assert [_] = Proca.TestEmailBackend.mailbox(action.supporter.email)
    end

    test "a testing action sends at most one representative message per locale", %{
      action: action,
      first_target: first_target
    } do
      other_target =
        Proca.Target.all(campaign: first_target.campaign)
        |> Enum.find(&(&1.id != first_target.id))

      Factory.insert(:message, action: action, target: other_target)

      MTTContext.deliver_test_mails(action.id)

      assert [_] = Proca.TestEmailBackend.mailbox(action.supporter.email)
    end

    test "concurrent duplicate test events send once", %{action: action} do
      results =
        1..2
        |> Enum.map(fn _ -> Task.async(fn -> MTTContext.deliver_test_mails(action.id) end) end)
        |> Enum.map(&Task.await(&1, 5_000))

      assert Enum.all?(results, &(&1 == :ok))
      assert [_] = Proca.TestEmailBackend.mailbox(action.supporter.email)
    end

    test "temporary test provider failure remains unsent and fails the queue event", %{
      action: action
    } do
      Proca.TestEmailBackend.fail_delivery(:temporary)
      {:ok, payload} = JSON.encode(%{actionId: action.id, testing: true})

      queue_message = %Broadway.Message{
        data: payload,
        acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
      }

      result = MTTTestStage.handle_message(:default, queue_message, nil)

      assert {:failed, _} = result.status

      refute Repo.exists?(
               from(m in Proca.Action.Message,
                 where: m.action_id == ^action.id and m.sent == true
               )
             )
    end

    test "acks away garbage payloads" do
      for payload <- ["not json", ~s({"some": "thing"})] do
        message = %Broadway.Message{
          data: payload,
          acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
        }

        result = MTT.handle_message(:default, message, nil)

        assert {:failed, _} = result.status
      end
    end
  end

  describe "queue names" do
    test "uses one global test queue and one live queue per org", %{target: target} do
      assert Topology.mtt_test_queue() == "wrk.mtt.test"

      assert Topology.mtt_queue(target.campaign.org) ==
               "wrk.#{target.campaign.org.id}.mtt"
    end
  end

  describe "dispatch_message/2" do
    test "fails closed when org queue topology is not running", %{
      target: %{emails: [%{email: email}]} = target
    } do
      target = %{target | campaign: MTTContext.get_target(target.id).campaign}
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      assert MTTContext.dispatch_message(target, msg) == {:error, :mtt_queue_unavailable}
      refute Repo.get(Proca.Action.Message, msg.id).sent
      assert [] = Proca.TestEmailBackend.mailbox(email)
    end

    test "dry run does not publish, send, or mutate", %{
      target: %{emails: [%{email: email}]} = target
    } do
      previous = Application.get_env(:proca, Proca.Server.MTT)
      Application.put_env(:proca, Proca.Server.MTT, mode: :dry_run)
      on_exit(fn -> Application.put_env(:proca, Proca.Server.MTT, previous) end)

      target = %{target | campaign: MTTContext.get_target(target.id).campaign}
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      handler_id = "mtt-dry-run-#{System.unique_integer([:positive])}"
      parent = self()

      :telemetry.attach(
        handler_id,
        [:proca, :mtt, :delivery],
        fn event, measurements, metadata, _ ->
          send(parent, {:mtt_telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert MTTContext.dispatch_message(target, msg) == :dry_run
      refute Repo.get(Proca.Action.Message, msg.id).sent
      assert [] = Proca.TestEmailBackend.mailbox(email)

      assert_receive {:mtt_telemetry, [:proca, :mtt, :delivery], %{count: 1}, metadata}
      assert metadata.kind == :live
      assert metadata.result == :dry_run
      assert metadata.org_id == target.campaign.org.id
      assert metadata.campaign_id == target.campaign.id
    end
  end

  describe "final live-delivery guards" do
    test "rejects a payload whose target does not own the message", %{
      target: target,
      first_target: wrong_target
    } do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      assert MTT.deliver(msg.id, wrong_target.id) == {:discard, :target_mismatch}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "rejects testing actions from the live queue", %{action: action, first_target: target} do
      msg = Factory.insert(:message, action: action, target: target)

      assert MTT.deliver(msg.id, target.id) == {:discard, :testing_action}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "rejects closed campaigns", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)
      Repo.update!(Ecto.Changeset.change(target.campaign, status: :closed))

      assert MTT.deliver(msg.id, target.id) == {:discard, :campaign_inactive}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "rejects messages after MTT end_at", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      Repo.update!(
        Ecto.Changeset.change(target.campaign.mtt,
          end_at: DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)
        )
      )

      assert MTT.deliver(msg.id, target.id) == {:discard, :mtt_ended}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "rejects targets without a sendable email without marking sent", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      Enum.each(target.emails, fn email ->
        Proca.TargetEmail.mark_one(email.id, :bounce)
      end)

      assert MTT.deliver(msg.id, target.id) == {:discard, :no_sendable_email}
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "concurrent duplicate deliveries send only once", %{
      target: %{emails: [%{email: email}]} = target
    } do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      results =
        1..2
        |> Enum.map(fn _ -> Task.async(fn -> MTT.deliver(msg.id, target.id) end) end)
        |> Enum.map(&Task.await(&1, 5_000))

      assert :ok in results
      assert Enum.any?(results, &(&1 == :ignore))
      assert [_] = Proca.TestEmailBackend.mailbox(email)
    end

    test "temporary provider failure remains unsent and fails the queue message", %{
      target: target
    } do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)
      Proca.TestEmailBackend.fail_delivery(:temporary)

      {:ok, payload} = JSON.encode(%{messageId: msg.id, targetId: target.id})

      queue_message = %Broadway.Message{
        data: payload,
        acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
      }

      result = MTT.handle_message(:default, queue_message, nil)

      assert {:failed, _} = result.status
      refute Repo.get(Proca.Action.Message, msg.id).sent
    end

    test "retry exhaustion acknowledges the queue event without marking sent", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)
      previous = Application.get_env(:proca, Proca.Pipes)
      Application.put_env(:proca, Proca.Pipes, Keyword.put(previous, :retry_limit, 3))
      on_exit(fn -> Application.put_env(:proca, Proca.Pipes, previous) end)

      {:ok, payload} = JSON.encode(%{messageId: msg.id, targetId: target.id})

      queue_message = %Broadway.Message{
        data: payload,
        metadata: %{
          headers: [
            {"x-death", :array,
             [
               table: [
                 {"count", :long, 3},
                 {"queue", :longstr, "wrk.#{target.campaign.org_id}.mtt"}
               ]
             ]}
          ]
        },
        acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
      }

      result = MTT.handle_message(:default, queue_message, nil)
      persisted = Repo.get!(Proca.Action.Message, msg.id)

      assert result.status == :ok
      refute persisted.sent
      assert msg.id in Enum.map(MTTContext.get_pending_messages(target.id, :all), & &1.id)
    end
  end

  describe "get_unsent_message/1 and get_target/1" do
    test "get_target loads campaign, mtt and email backend", %{target: target} do
      loaded = MTTContext.get_target(target.id)

      assert loaded.id == target.id
      assert loaded.campaign.mtt != nil
      assert loaded.campaign.org.email_backend != nil
    end

    test "get_unsent_message only returns unsent delivered messages", %{target: target} do
      [msg | _] = MTTContext.get_pending_messages(target.id, :all)

      assert MTTContext.get_unsent_message(msg.id).id == msg.id

      Proca.Action.Message.mark_one(msg, :sent)
      assert MTTContext.get_unsent_message(msg.id) == nil
    end
  end
end
