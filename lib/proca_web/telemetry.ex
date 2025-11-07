defmodule ProcaWeb.Telemetry do
  @moduledoc false

  use Supervisor
  require Logger

  import Ecto.Query
  import Telemetry.Metrics

  alias Proca.Action.Message

  @campaign_tags [:campaign_id, :campaign_name]

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children =
      if enable_telemetry?() do
        [
          {
            :telemetry_poller,
            measurements: periodic_measurements(),
            period: :timer.seconds(60),
            init_delay: :timer.seconds(30)
          },
          {
            TelemetryMetricsPrometheus,
            [
              metrics: metrics(),
              port: prometheus_port()
            ]
          }
        ]
      else
        []
      end

    :telemetry.attach(
      "query-time-handler",
      [:proca, :repo, :query],
      &ProcaWeb.Telemetry.handle_event/4,
      []
    )

    Supervisor.init(children, strategy: :one_for_one)
  end

  def handle_event(
        [:proca, :repo, :query],
        measurements,
        %{options: %{event: :export_actions, org_id: org_id}},
        _config
      ) do
    query_duration = System.convert_time_unit(measurements.total_time, :native, :millisecond)

    :telemetry.execute(
      [:proca, :exporter, :export_actions],
      %{export_time: query_duration, count: 1},
      %{org_id: org_id}
    )
  end

  def handle_event([:proca, :repo, :query], measurements, _metadata, _config) do
    query_duration = System.convert_time_unit(measurements.query_time, :native, :millisecond)

    if query_duration > 10_000 do
      Logger.warning("""
      Slow query detected (#{query_duration}ms)
      """)
    end
  end

  def count_sendable_messages do
    active_campaigns =
      from(
        c in Proca.Campaign,
        join: mtt in Proca.MTT,
        on: mtt.campaign_id == c.id,
        where: mtt.start_at <= from_now(0, "day") and mtt.end_at >= from_now(0, "day"),
        preload: [:mtt],
        order_by: fragment("RANDOM()")
      )
      |> Proca.Repo.all()

    Enum.each(active_campaigns, fn campaign ->
      unsent_messages =
        Message.select_by_campaign(campaign.id)
        |> Proca.Repo.all()
        |> length()

      :telemetry.execute([:proca, :mtt], %{sendable_messages: unsent_messages}, %{
        campaign_id: campaign.id,
        campaign_name: campaign.name
      })
    end)
  end

  defp metrics do
    [
      # API Metrics
      last_value("proca.exporter.export_actions.export_time",
        unit: {:native, :millisecond},
        tags: [:org_id]
      ),
      sum("proca.exporter.export_actions.count", tags: [:org_id]),
      # MTT Metrics
      counter("proca.mailjet.events.count", tags: [:reason]),
      counter("proca.mailjet.bounces.count", tags: [:reason]),
      last_value("proca.mtt.campaigns_running"),
      last_value("proca.mtt.sendable_messages", tags: @campaign_tags),
      last_value("proca.mtt.sendable_targets", tags: @campaign_tags),
      last_value("proca.mtt.current_cycle", tags: @campaign_tags),
      last_value("proca.mtt.all_cycles", tags: @campaign_tags),
      sum("proca.mtt.messages_sent", tags: @campaign_tags),

      # MTT New Algo
      # currently running target with max_emails_per_hour
      counter("proca.mtt_new.target_started.count",
        tags: [:target_id, :max_emails_per_hour]
      ),
      # count sent messages per target
      counter("proca.mtt_new.deliver_message.count", tags: [:target_id]),

      # Database Metrics
      last_value("proca.repo.query.total_time", unit: {:native, :millisecond}),
      last_value("proca.repo.query.decode_time", unit: {:native, :millisecond}),
      last_value("proca.repo.query.query_time", unit: {:native, :millisecond}),
      last_value("proca.repo.query.queue_time", unit: {:native, :millisecond}),
      last_value("proca.repo.query.idle_time", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      {ProcaWeb.Telemetry, :count_sendable_messages, []}
    ]
  end

  defp enable_telemetry? do
    Application.get_env(:proca, ProcaWeb.Telemetry, enable: true)[:enable]
  end

  defp prometheus_port do
    Application.get_env(:proca, __MODULE__, port: 9568)[:port]
  end
end
