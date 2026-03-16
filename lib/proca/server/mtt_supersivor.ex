defmodule Proca.Server.MTTSupervisor do
  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_mtt_scheduler(target, max_emails_per_hour) do
    child_spec = %{
      id: {:message_scheduler, target.id},
      start: {Proca.Server.MTTScheduler, :start_link, [target, max_emails_per_hour]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
