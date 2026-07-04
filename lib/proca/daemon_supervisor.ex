defmodule Proca.DaemonSupervisor do
  @moduledoc """
  GenServer that starts background daemon servers after a configurable delay.

  The delay allows the main application (HTTP endpoint, DB pool, PubSub) to
  start and become ready before expensive background services (MTT, Stats,
  OldActions, etc.) are initialized.

  Once the delay elapses, a dedicated `Supervisor` is started for the daemon
  children so they are properly supervised and restarted on failure.
  """
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    delay = Keyword.get(opts, :delay, 5_000)

    if delay > 0 do
      Logger.info("DaemonSupervisor will start background services in #{delay}ms")
      Process.send_after(self(), :start_daemons, delay)
      {:ok, %{started: false}}
    else
      Logger.info("DaemonSupervisor starting background services immediately")
      start_daemons()
      {:ok, %{started: true}}
    end
  end

  @impl true
  def handle_info(:start_daemons, state) do
    Logger.info("DaemonSupervisor starting background services now")
    start_daemons()
    {:noreply, %{state | started: true}}
  end

  defp start_daemons do
    children = Proca.Application.daemon_servers()

    case Supervisor.start_link(children, strategy: :one_for_one, name: Proca.DaemonSupervisor.Instance) do
      {:ok, pid} ->
        Logger.info("DaemonSupervisor started background service supervisor (#{inspect(pid)})")

      {:error, {:already_started, pid}} ->
        Logger.debug("DaemonSupervisor already started (#{inspect(pid)})")

      {:error, reason} ->
        Logger.error("DaemonSupervisor failed to start: #{inspect(reason)}")
    end

    :ok
  end
end
