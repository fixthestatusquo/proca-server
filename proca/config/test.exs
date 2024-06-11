use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
config :proca, Proca.Repo,
  username: "proca",
  password: "proca",
  database: "proca_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :proca, Proca.Server.MTTWorker, max_messages: 6

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :proca, ProcaWeb.Endpoint,
  http: [port: 4002],
  server: false,
  router: ProcaWeb.Router

# Print only warnings and errors during test
# config :logger, level: :debug
config :logger, level: :warn

config :proca, Proca,
  org_name: "instance",
  start_daemon_servers: false
