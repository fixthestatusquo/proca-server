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
end
