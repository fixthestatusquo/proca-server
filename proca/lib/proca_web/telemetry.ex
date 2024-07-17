defmodule ProcaWeb.Telemetry do
  @moduledoc false

  use Supervisor
  require Logger

  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {TelemetryMetricsPrometheus, [metrics: metrics()]}
    ]

    :telemetry.attach(
      "query-time-handler",
      [:proca, :repo, :query],
      &ProcaWeb.Telemetry.handle_event/4,
      []
    )

    Supervisor.init(children, strategy: :one_for_one)
  end

  def handle_event([:proca, :repo, :query], measurements, metadata, _config) do
    query_time_ms = measurements[:query_time] / (1_000 * 1_000)

    if query_time_ms > 5_000 do
      Logger.warning("Database query took #{query_time_ms}ms", metadata)
    end
  end

  defp metrics do
    [
      last_value("proca.mtt.campaigns_running"),
      last_value("proca.mtt.sendable_targets", tags: [:campaign_id]),
      last_value("proca.mtt.current_cycle", tags: [:campaign_id]),
      last_value("proca.mtt.all_cycles", tags: [:campaign_id])
    ]
  end
end
