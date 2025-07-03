defmodule Proca.TestProcessing do
  use ExUnit.CaseTemplate

  @doc """
  Setup test context
  """
  def test_processing(context) do
    assert Proca.Pipes.Connection.is_connected?()

    processing =
      Proca.Stage.Action.start_link(
        name: __MODULE__,
        producer: {Broadway.DummyProducer, []}
      )

    pid =
      case processing do
        {:ok, pid} ->
          # Lets just start single Processing, and not close it after test is done
          Process.unlink(pid)
          pid

        # share that Processing with other tests
        {:error, {:already_started, pid}} ->
          pid
      end

    Map.put(context, :processing, pid)
  end

  using do
    quote do
      import Proca.TestProcessing,
        only: [
          process: 1,
          test_processing: 1
        ]

      setup :test_processing
    end
  end

  def process(action) do
    ref = Broadway.test_message(__MODULE__, action)
    assert_receive {:ack, ^ref, good, bad}, 1000

    # for testing acknowledger is replaced so we run ours
    Proca.Stage.Action.ack(:store, good, bad)

    case good do
      [%{data: action2}] -> {:ok, action2}
      _ -> :error
    end
  end
end
