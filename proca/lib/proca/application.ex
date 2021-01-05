defmodule Proca.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Proca.Repo,
      # Start the PubSub server
      {Phoenix.PubSub, name: Proca.PubSub},
      # Start the endpoint when the application starts
      ProcaWeb.Endpoint,
      {Absinthe.Subscription, ProcaWeb.Endpoint},

      {Proca.Server.Keys, Application.get_env(:proca, Proca)[:org_name]},

      {Proca.Server.Stats, Application.get_env(:proca, Proca)[:stats_sync_interval]},

      {Proca.Pipes.Connection, Application.get_env(:proca, Proca.Pipes)[:url]},
      {Registry, [keys: :unique, name: Proca.Pipes.Registry]},
      {Proca.Pipes.Supervisor, []},
      {Proca.Server.Processing, []},

      # {Proca.Stage.ThankYou, []},
      # {Proca.Stage.SQS, []}
      # Starts a worker by calling: Proca.Worker.start_link(arg)
      # {Proca.Worker, arg},
    ]

    children =
      if enabled(:jwt) do
        children ++
          [
            {
              Proca.Server.Jwks,
              Application.get_env(:proca, Proca.Server.Jwks)[:url]
            }
          ]
      else
        children
      end

    # AMQP logging is very verbose so quiet it:
    :logger.add_primary_filter(
      :ignore_rabbitmq_progress_reports,
      {&:logger_filters.domain/2, {:stop, :equal, [:progress]}}
    )

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

  defp enabled(:jwt) do
    not is_nil(Application.get_env(:proca, Proca.Server.Jwks)[:url])
  end
end
