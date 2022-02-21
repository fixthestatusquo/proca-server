defmodule Proca.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Standard Phoenix processes
    children = [
      # Start the Ecto repository
      Proca.Repo,
      # Start the PubSub server
      {Phoenix.PubSub, name: Proca.PubSub},
      # Start the endpoint when the application starts
      ProcaWeb.Endpoint,
      {Absinthe.Subscription, ProcaWeb.Endpoint},

      # Core servers (data providers and caches)
      # Dynamic instance configuration
      {Proca.Server.Instance, Proca.Org.instance_org_name()},

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
      {Proca.Server.Processing, []},
      {Proca.Server.Stats, Application.get_env(:proca, Proca)[:stats_sync_interval]},
      {Proca.Stage.ProcessOld, Application.get_env(:proca, Proca)[:process_old_interval]},
      {Proca.ActionPage.Status, []},
      {Proca.Server.Jwks, Application.get_env(:proca, Proca.Server.Jwks)[:url]},
      {Proca.Server.MTT, []}
    ]
  end
end
