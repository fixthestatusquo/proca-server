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
end
