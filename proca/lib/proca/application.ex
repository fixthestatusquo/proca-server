defmodule Proca.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
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

      # Processing / queue management
      {Registry, [keys: :unique, name: Proca.Pipes.Registry]},
      {Proca.Pipes.Supervisor, []},
      {Proca.Pipes.Connection, Proca.Pipes.queue_url()}
    ]

    # Proca SErvers
    children =
      children ++
        if Application.get_env(:proca, Proca)[:start_daemon_servers] do
          daemon_servers()
        else
          []
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

  defp daemon_servers() do
    [
      # Async processing systems
      %{
        id: Proca.Stage.CurrentActions,
        start: {
          Proca.Stage.Action,
          :start_link,
          [[producer: {Proca.Stage.Queue, []}]]
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
      # MTT cron job
      {Proca.Server.MTT, []},
      # User status
      {Proca.Users.Status, [interval: 30_000]}
    ]
  end
end
