defmodule Proca.Server.MTTMailerTest do
  use Proca.DataCase
  @moduletag start: []

  alias Proca.Server.MTTMailer

  setup do
    previous_paused = MTTMailer.paused?()
    previous_worker = Application.get_env(:proca, Proca.Server.MTTWorker)

    on_exit(fn ->
      MTTMailer.set_paused(previous_paused)

      if previous_worker do
        Application.put_env(:proca, Proca.Server.MTTWorker, previous_worker)
      else
        Application.delete_env(:proca, Proca.Server.MTTWorker)
      end
    end)

    MTTMailer.set_paused(false)
    :ok
  end

  test "pause and start toggle the runtime processor flag without restart" do
    assert MTTMailer.start() == :ok
    refute MTTMailer.paused?()
    assert MTTMailer.status().paused == false

    assert MTTMailer.pause() == :ok
    assert MTTMailer.paused?()
    assert MTTMailer.status().paused == true

    assert MTTMailer.start() == :ok
    refute MTTMailer.paused?()
  end

  test "max_messages_per_cycle can be changed at runtime" do
    assert MTTMailer.set_max_messages_per_cycle(42) == :ok
    assert MTTMailer.max_messages_per_cycle() == 42
    assert MTTMailer.status().max_messages_per_cycle == 42
  end

  test "set_max_messages_per_cycle rejects non-positive values" do
    assert MTTMailer.set_max_messages_per_cycle(0) == {:error, :invalid_max_messages}
    assert MTTMailer.set_max_messages_per_cycle(-1) == {:error, :invalid_max_messages}
  end
end
