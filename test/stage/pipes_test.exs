defmodule Proca.PipesTest do
  use Proca.DataCase

  @failed_metadata %{
    headers: [
      {"x-death", :array,
       [
         table: [
           {"count", :long, 55613},
           {"exchange", :longstr, "org.320.deliver"},
           {"queue", :longstr, "cus.320.deliver"},
           {"reason", :longstr, "rejected"},
           {"routing-keys", :array, [longstr: "register.fur_free_europe"]},
           {"time", :timestamp, 1_664_450_213}
         ],
         table: [
           {"count", :long, 55612},
           {"exchange", :longstr, "org.320.fail"},
           {"queue", :longstr, "org.320.fail"},
           {"reason", :longstr, "expired"},
           {"routing-keys", :array, [longstr: "cus.320.deliver"]},
           {"time", :timestamp, 1_664_450_243}
         ]
       ]},
      {"x-first-death-exchange", :longstr, "org.320.deliver"},
      {"x-first-death-queue", :longstr, "cus.320.deliver"},
      {"x-first-death-reason", :longstr, "rejected"}
    ]
  }

  test "times_retired" do
    msg = %Broadway.Message{
      data: "",
      acknowledger: Broadway.NoopAcknowledger,
      metadata: @failed_metadata
    }

    assert Proca.Stage.Support.times_retried(msg) == 55613
  end

  test "times_retried does not crash on a first-time message with no x-death header" do
    # RabbitMQ represents "no headers property at all" as :undefined, not [] -
    # this is the shape of every message on its first delivery attempt, before
    # it has ever been dead-lettered.
    msg = %Broadway.Message{
      data: "",
      acknowledger: Broadway.NoopAcknowledger,
      metadata: %{headers: :undefined}
    }

    assert Proca.Stage.Support.times_retried(msg) == 0
  end

  test "too_many_retries? uses the configured numeric limit" do
    previous = Application.get_env(:proca, Proca.Pipes)
    Application.put_env(:proca, Proca.Pipes, Keyword.put(previous, :retry_limit, 3))
    on_exit(fn -> Application.put_env(:proca, Proca.Pipes, previous) end)

    assert Proca.Stage.Support.too_many_retries?(%Broadway.Message{
             data: "",
             acknowledger: Broadway.NoopAcknowledger,
             metadata: @failed_metadata
           })
  end

  test "MTT fail queue TTL is 30 minutes" do
    assert Proca.Pipes.Topology.mtt_fail_ttl_ms() == 1_800_000
  end

  test "wrk.mtt.test has a dead-letter circuit so failed messages park instead of vanishing" do
    alias Proca.Pipes.Topology

    args = Topology.mtt_test_retry_queue_arguments()

    assert {"x-dead-letter-exchange", :longstr, Topology.mtt_test_fail_exchange()} in args
    assert {"x-dead-letter-routing-key", :longstr, Topology.mtt_test_queue()} in args
  end
end
