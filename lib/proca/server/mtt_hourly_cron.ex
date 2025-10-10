defmodule Proca.Server.MTTHourlyCron do
  use GenServer
  require Logger

  alias Proca.Server.MTTContext
  alias Proca.Server.MTTSupervisor

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_next_hour()

    {:ok, state}
  end

  defp schedule_next_hour() do
    now = DateTime.utc_now()

    next_hour =
      %{now | minute: 0, second: 0, microsecond: {0, 0}}
      |> DateTime.add(3600, :second)

    interval = DateTime.diff(next_hour, now, :millisecond)

    Logger.info("Next MTT CRON run in #{interval}")

    Process.send_after(self(), :run_mtt, interval)
  end

  @impl true
  def handle_info(:run_mtt, state) do
    MTTContext.dupe_rank()

    MTTContext.get_active_targets()
    |> Enum.each(fn target ->
      max_emails_per_hour = MTTContext.max_emails_per_hour(target.campaign)

      MTTSupervisor.start_mtt_scheduler(target, max_emails_per_hour)
    end)

    schedule_next_hour()

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.info("MTT CRON down ref #{inspect(ref)} reason #{inspect(reason)}")

    {:noreply, state}
  end
end
