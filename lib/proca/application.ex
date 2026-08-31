defmodule Proca.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    version = Application.spec(:proca, :vsn)
    log_level = Logger.level()
    Logger.error("starting proca #{version} log level #{log_level}")

    # Standard Phoenix processes
    children = [
      # Start the Telemetry supervisor
      ProcaWeb.Telemetry,

      # Start the Ecto repository
      Proca.Repo,
      # Start the PubSub server
      {Phoenix.PubSub, name: Proca.PubSub},
      # Start the endpoint when the application starts
      ProcaWeb.Endpoint,
      {Absinthe.Subscription, ProcaWeb.Endpoint},

      # Core servers (data providers and caches)

      # Encryption
      {Proca.Server.Keys, Proca.Org.instance_org_name()},

      # Email template directory
      {Proca.Service.EmailTemplateDirectory, []},

      # TTL cache for preloaded action pages (its ETS table is created at boot)
      {Proca.ActionPage.Cache, []},

      # In-memory counters for transactional email backend warming/budget
      {Proca.Service.EmailBudget, []},

      # Processing / queue management
      {Registry, [keys: :unique, name: Proca.Pipes.Registry]},
      {Proca.Pipes.Supervisor, []},
      {Proca.Pipes.Connection, Proca.Pipes.queue_url()},

      # Start the email preview org storage
      {Proca.Service.Preview.OrgStorage, []}
    ]

    # MTT in-flight publish tracking (prevents drip republish while a message
    # is still in wrk.N.mtt / org.N.mtt.fail).
    _ = Proca.Server.MTTContext.ensure_in_flight_table()

    # Proca Servers — started via DaemonSupervisor with a short delay so the
    # HTTP endpoint and DB pool are ready first. Set delay to 0 to start
    # synchronously. Disable entirely with start_daemon_servers: false.
    daemon_delay =
      if Application.get_env(:proca, Proca)[:start_daemon_servers] do
        Application.get_env(:proca, Proca)[:daemon_start_delay] || 5_000
      else
        :disabled
      end

    children =
      if daemon_delay == :disabled do
        children
      else
        children ++ [{Proca.DaemonSupervisor, [delay: daemon_delay]}]
      end

    # AMQP logging is very verbose so quiet it:
    :logger.add_primary_filter(
      :ignore_rabbitmq_progress_reports,
      {&:logger_filters.domain/2, {:stop, :equal, [:progress]}}
    )

    # Sentry logger
    Logger.add_backend(Sentry.LoggerBackend)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Proca.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ProcaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def daemon_servers() do
    # Broadway processors concurrency for the current-actions pipeline.
    # Configurable via ACTION_PROCESSING_CONCURRENCY (default 40).
    current_actions_concurrency =
      Application.get_env(:proca, Proca)[:action_processing_concurrency]

    [
      # Async processing systems
      %{
        id: Proca.Stage.CurrentActions,
        start: {
          Proca.Stage.Action,
          :start_link,
          [
            [
              producer: {Proca.Stage.Queue, []},
              processors_concurrency: current_actions_concurrency
            ]
          ]
        }
      },
      %{
        id: Proca.Stage.OldActions,
        start: {
          Proca.Stage.Action,
          :start_link,
          [
            [
              name: Proca.Stage.OldActions,
              producer: {
                Proca.Stage.UnprocessedActions,
                [sweep_interval: 600, time_margin: 60]
              },
              processors_concurrency: 1
            ]
          ]
        }
      },

      # Stats
      {Proca.Server.Stats, Application.get_env(:proca, Proca)[:stats_sync_interval]},
      {Proca.ActionPage.Status, []},
      # JWT keys dict
      {Proca.Server.Jwks, Application.get_env(:proca, ProcaWeb.UserAuth)[:sso][:jwks_url]},
      # MTT test-actions consumer. Always runs (even when MTT_MODE=disabled), so
      # test MTT emails are always delivered regardless of the live MTT pipeline
      # being on/off/dry_run.
      {Proca.Stage.MTTTest, []},
      # Confirm reminder cron
      {Proca.Server.ConfirmReminderCron,
       Application.get_env(:proca, Proca.Server.ConfirmReminderCron, [])},
      # User status
      {Proca.Users.Status, [interval: 30_000]}
    ] ++ mtt_daemon_servers()
  end

  defp mtt_daemon_servers do
    # enabled?/1 is true for both :enabled and :dry_run, false for :disabled.
    # This keeps the pipeline booted for dry_run (so it can rehearse without
    # sending) while :disabled is a full kill-switch that boots nothing.
    if Proca.Server.MTT.enabled?() do
      [
        # MTT processing pipeline (cron/driver, dynamic schedulers, RabbitMQ consumers)
        {Proca.Server.MTT, []},
        {Registry, [name: Proca.Server.MTTSchedulerRegistry, keys: :unique]},
        {Proca.Server.MTTSupervisor, []},
        {Proca.Server.MTTHourlyCron, []}
      ]
    else
      Logger.info("MTT processing disabled (MTT_MODE=disabled)")
      []
    end
  end
end
