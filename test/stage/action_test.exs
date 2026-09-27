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

      capture_log(fn ->
        assert Action.ack(:store, [deliver_message(action)], []) == :ok
      end)

      assert Repo.get!(Proca.Action, action.id).processing_status == :delivered
    end

    test "a publish failure ({:error, reason}, not the bare :error atom) is logged and captured, not raised" do
      %{action: action} = mtt_story()

      # Force the failure deterministically: with a broker reachable (CI),
      # Connection.publish succeeds and there is no failure path to exercise.
      # The seam is a regression guard for a real bug: the case in ack/3 used to
      # only match the bare :error atom, which Connection.publish/4 never returns
      # (its spec is `:ok | {:error, term()}`), so the failure crashed the whole
      # ack callback with a CaseClauseError instead of being handled.
      previous = Application.get_env(:proca, :mtt_test_publish_fun)

      Application.put_env(:proca, :mtt_test_publish_fun, fn _data, _exchange, _rk, _chan ->
        {:error, :test_publish_failure}
      end)

      on_exit(fn ->
        if previous do
          Application.put_env(:proca, :mtt_test_publish_fun, previous)
        else
          Application.delete_env(:proca, :mtt_test_publish_fun)
        end
      end)

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
