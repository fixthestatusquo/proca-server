defmodule Proca.Stage.Queue do
  @moduledoc """
  A queue producer for Broadway.

  Create with Queue.start_link(name: Module)
  Call Queue.enqueue(Module, item) to async put item into queue

  State is: {queue, size_of_queue}
  """
  use GenStage

  @impl true
  def init(_opts) do
    queue = :queue.new()
    {:producer, {queue, 0, 0}}
  end

  @impl true
  def handle_demand(demand, {queue, size, prev_demand}) do
    #    IO.inspect({demand, size, prev_demand}, label: "DEMANDE")
    possible = min(demand + prev_demand, size)

    {supply, rest} = :queue.split(possible, queue)

    {:noreply, :queue.to_list(supply), {rest, size - possible, prev_demand + demand - possible}}
  end

  @impl true
  def handle_cast({:enqueue, items}, {queue, ct, pd}) when is_list(items) do
    handle_demand(
      0,
      {:queue.join(:queue.from_list(items), queue), ct + length(items), pd}
    )
  end

  @impl true
  def handle_cast({:enqueue, item}, {queue, ct, pd}) do
    handle_demand(
      0,
      {:queue.in(item, queue), ct + 1, pd}
    )
  end

  def enqueue(module, item) do
    GenStage.cast(module, {:enqueue, item})
  end
end
