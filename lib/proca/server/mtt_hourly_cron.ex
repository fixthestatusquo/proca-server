defmodule Proca.Server.MTTHourlyCron do
  use GenServer
  require Logger

  alias Proca.Server.MTTContext
  alias Proca.Server.MTTSupervisor

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, 60 * 60 * 1000)
    delay = calculate_time_delay(interval)
    ref = Process.send_after(self(), :run_mtt, delay)

    {:ok, %{interval: interval, timer_ref: ref}}
  end

  @impl true
  def handle_info(:run_mtt, %{interval: interval} = state) do
    ref = Process.send_after(self(), :run_mtt, interval)

    Logger.info("MTT CRON running at #{DateTime.utc_now()}, next in #{interval} ms (ref=#{inspect ref})")

    MTTContext.dupe_rank()
    targets_active = MTTContext.get_active_targets()

    targets_active
    |> Enum.each(fn target ->
      max_emails_per_hour = MTTContext.max_emails_per_hour(target.campaign)

      Logger.info("MTT max emails per hour #{max_emails_per_hour} for target #{target.id}")

      MTTSupervisor.start_mtt_scheduler(target, max_emails_per_hour)
    end)

    {:noreply, %{state | timer_ref: ref}}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.info("MTT CRON down ref #{inspect(ref)} reason #{inspect(reason)}")

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.error("MTT CRON terminating: #{inspect(reason)} state=#{inspect(state)}")
    :ok
  end

  defp calculate_time_delay(interval) when interval >= 60 * 60 * 1000 do
    now = DateTime.utc_now()

    next_run =
      DateTime.utc_now()
      |> Map.put(:minute, 0)
      |> Map.put(:second, 0)
      |> Map.put(:microsecond, {0, 0})
      |> DateTime.add(interval, :millisecond)

    max(DateTime.diff(next_run, now, :millisecond), 0)
  end

  defp calculate_time_delay(interval), do: interval
end
