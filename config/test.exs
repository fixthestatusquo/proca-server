import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
config :proca, Proca.Repo,
  username: System.get_env("DATABASE_USER", "proca"),
  password: System.get_env("DATABASE_PASS", "proca"),
  database: "proca_test",
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :proca, ProcaWeb.Endpoint,
  http: [port: 4002],
  server: false,
  router: ProcaWeb.Router

# Print only warnings and errors during test
# config :logger, level: :debug
config :logger, level: :warning

config :proca, Proca.Pipes,
  url: System.get_env("AMQP_URL", "amqp://proca:proca@localhost/proca")

config :proca, Proca,
  org_name: "instance",
  start_daemon_servers: false

config :proca, Proca.Server.MTTWorker, max_messages_per_cycle: 99
