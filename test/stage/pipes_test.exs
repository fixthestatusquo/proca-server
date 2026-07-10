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
end
