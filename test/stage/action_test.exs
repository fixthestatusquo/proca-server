defmodule Proca.Stage.ActionTest do
  use Proca.DataCase
  import ExUnit.CaptureLog
  import Proca.StoryFactory, only: [mtt_story: 0]

  alias Proca.Repo
  alias Proca.Factory
  alias Proca.Stage.{Action, Processing}

  defp deliver_message(action) do
    proc = %Processing{
      action_change: Ecto.Changeset.change(action, processing_status: :delivered),
      supporter_change: Ecto.Changeset.change(action.supporter),
      new_state: {:delivered, :accepted},
      stage: :deliver
    }

    %Broadway.Message{data: proc, acknowledger: Broadway.NoopAcknowledger}
  end

  describe "ack(:store, ...)" do
    test "persists processing_status and attempts the MTT test publish for a testing deliver-stage action" do
      %{action: action} = mtt_story()

      log =
        capture_log(fn ->
          assert Action.ack(:store, [deliver_message(action)], []) == :ok
        end)

      assert Repo.get!(Proca.Action, action.id).processing_status == :delivered
      assert log =~ "MTT test: action #{action.id} delivered, publishing to"
    end

    test "a publish failure ({:error, reason}, not the bare :error atom) is logged and captured, not raised" do
      %{action: action} = mtt_story()

      # No RabbitMQ connection in this test environment, so
      # publish_mtt_test_after_store/1 genuinely hits Connection.publish's
      # failure path here - this is a regression test for a real bug: the
      # case in ack/3 used to only match the bare :error atom, which
      # Connection.publish/4 never actually returns (its own spec is
      # `:ok | {:error, term()}`), so this failure crashed the whole ack
      # callback with a CaseClauseError instead of being handled.
      log =
        capture_log(fn ->
          assert Action.ack(:store, [deliver_message(action)], []) == :ok
        end)

      assert Repo.get!(Proca.Action, action.id).processing_status == :delivered
      assert log =~ "MTT test: publish failed after store for action #{action.id}"
    end

    test "does not attempt an MTT test publish for a non-testing action" do
      action = Factory.insert(:action, testing: false, processing_status: :new)

      log =
        capture_log(fn ->
          assert Action.ack(:store, [deliver_message(action)], []) == :ok
        end)

      assert Repo.get!(Proca.Action, action.id).processing_status == :delivered
      refute log =~ "MTT test:"
    end
  end
end
