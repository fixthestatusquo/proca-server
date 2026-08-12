defmodule Proca.Server.ConfirmReminderCron do
  @moduledoc """
  Hourly cron that sends reminder emails to unconfirmed supporters.
  """
  use GenServer
  require Logger

  @default_interval_ms :timer.hours(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval_ms)
    Process.send_after(self(), :run, interval)
    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:run, %{interval: interval} = state) do
    Process.send_after(self(), :run, interval)
    Logger.info("ConfirmReminderCron: running at #{DateTime.utc_now()}")

    try do
      Proca.Supporter.ConfirmReminder.run()
    rescue
      e -> Logger.error("ConfirmReminderCron: error #{inspect(e)}")
    end

    {:noreply, state}
  end
end
