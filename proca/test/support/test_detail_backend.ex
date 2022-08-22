defmodule Proca.TestDetailBackend do
  def start_link(detail) do
    case Process.whereis(__MODULE__) do
      pid when is_pid(pid) ->
        Agent.update(__MODULE__, fn _d -> detail end)
        {:ok, pid}

      nil ->
        Agent.start_link(fn -> detail end, name: __MODULE__)
    end
  end

  def lookup(_supporter) do
    {:ok, Agent.get(__MODULE__, & &1)}
  end

  @doc """

  When testing, we want to make sure processing finished, and when processing
  calls details service asynchronously, we'd call to details, then it calls to
  processing, so that the message guarantee ordering to us. This will be faster
  then adding an artificial sleep()

  XXX Hopefully there can be nor race this way

  """
  def sync() do
    Agent.get(__MODULE__, fn _d ->
      Proca.Stage.Processing.sync()
    end)
  end
end
