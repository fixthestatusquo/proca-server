import Config

database_url =
  System.get_env("DATABASE_URL") ||
  raise """
  environment variable DATABASE_URL is missing.
  For example: ecto://USER:PASS@HOST/DATABASE
  """

config :proca, Proca.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET") || "50"),
  queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL") || "1000")

config :proca, Proca.Server.Plumbing,
  url: System.get_env("AMQP_URL") || System.get_env("CLOUDAMQP_URL")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
  raise """
  environment variable SECRET_KEY_BASE is missing.
  You can generate one by calling: mix phx.gen.secret
  """

live_view_signing_salt =
  System.get_env("SIGNING_SALT") ||
  raise """
  environment variable SIGNING_SALT is missing.
  You can generate one by calling: mix phx.gen.secret
  """

bind_ip = System.get_env("LISTEN_IP", "0.0.0.0")
|> String.split(".")
|> Enum.map(&String.to_integer/1)
|> List.to_tuple

config :proca, ProcaWeb.Endpoint,
  url: [host: System.get_env("DOMAIN")],
  http: [
    ip: bind_ip,
    port: String.to_integer(System.get_env("PORT") || "4000")
    # transport_options: [socket_opts: [:inet6]]
  ],
  check_origin: ["//" <> System.get_env("DOMAIN")],
  secret_key_base: secret_key_base

config :proca, Proca,
  org_name: System.get_env("ORG_NAME"),
  stats_sync_interval: String.to_integer(System.get_env("SYNC_INTERVAL") || "5000")


# Configures Elixir's Logger
config :logger,
  backends: [:console, Sentry.LoggerBackend, {LoggerFileBackend, :error_log}],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: System.get_env("LOGS_DIR") <> "/error.log",
  level: :error
