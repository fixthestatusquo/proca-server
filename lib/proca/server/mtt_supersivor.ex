defmodule Proca.Server.MTTSupervisor do
  use DynamicSupervisor
  require Logger

  @registry Proca.Server.MTTSchedulerRegistry

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_mtt_scheduler(target, max_emails_per_hour) do
    via_name = {:via, Registry, {@registry, {:mtt_scheduler, target.id}}}

    child_spec = %{
      id: {:message_scheduler, target.id},
      start:
        {Proca.Server.MTTScheduler, :start_link, [target, max_emails_per_hour, [name: via_name]]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Sentry.capture_message("MTT scheduler for target already running, skipped",
          extra: %{target_id: target.id, existing_pid: inspect(pid)}
        )

        :telemetry.execute(
          [:mtt, :throttle, :scheduler, :skip],
          %{},
          %{target_id: target.id, campaign_id: target.campaign.id, reason: :already_running}
        )

        {:error, :already_running}

      {:error, reason} = error ->
        Logger.error("MTT scheduler for target #{target.id} failed to start: #{inspect(reason)}")

        Sentry.capture_message("MTT scheduler failed to start",
          extra: %{target_id: target.id, reason: inspect(reason)}
        )

        :telemetry.execute(
          [:mtt, :throttle, :scheduler, :skip],
          %{},
          %{target_id: target.id, campaign_id: target.campaign.id, reason: :start_failed}
        )

        error

      other ->
        other
    end
  end
end
