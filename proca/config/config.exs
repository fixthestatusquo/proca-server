# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :proca,
  ecto_repos: [Proca.Repo]

# Configures the endpoint
config :proca, ProcaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AW/2W3wBPlNgOj39H7IGyyI9Ycp+hScpt/oaQTvE6m2fGnrxHKVUR3AVhLRDq/QL",
  signing_salt: "uM50prEz688OESGJwzwxmFgxf5ZRaw4w",
  render_errors: [view: ProcaWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Proca.PubSub,
  allow_origin: "*",
  router: if(System.get_env("ENABLE_ECI"), do: ProcaWeb.EciRouter, else: ProcaWeb.Router)

config :cors_plug,
  origin: &ProcaWeb.Router.allow_origin/0

config :proca, ProcaWeb.UserAuth,
  local: [enabled: true],
  require_verified_email: false,
  sso: [
    enabled: false,
    home_url: "https://account.fixthestatusquo.org",
    jwt_secret: nil,
    jwks_url: nil,
    jwt: [
      email_path: nil,
      email_verified_path: nil
    ]
  ]

# Willfully leaked Hcaptcha secret (used only for development)
# config :proca, ProcaWeb.Resolvers.Captcha,
#  hcaptcha: "0x8565EF658CA7fdE55203a4725Dd341b5147dEcf2"
#  procaptcha_url: "https://captcha.proca.app"

config :proca, ProcaWeb.Resolvers.Captcha,
  captcha_service: "procaptcha",
  procaptcha_url: "https://captcha.proca.app"

config :proca, Proca,
  org_name: "instance",
  # XXX move to Proca.Server.Stats
  stats_sync_interval: 0,
  # XXX move to Proca.Server.Stats
  process_old_interval: 0,
  start_daemon_servers: true,
  mtt_cycle_time: 3

# FPR seed only for development
config :proca, Proca.Supporter, fpr_seed: "4xFc6MsafPEwc6ME"

config :proca, Proca.Pipes,
  url: "amqp://proca:proca@localhost/proca",
  ssl_options: nil,
  retry_limit: 3

# Disable lager logging (included by rabbitmq app)
config :lager, handlers: []

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, :adapter, Tesla.Adapter.Mint

# ExAws has dependency on hackney, nothing to do about it
config :ex_aws,
  http_client: Proca.Service

config :ex_aws_sqs, parser: ExAws.SQS.SweetXmlParser

config :sentry,
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  capture_log_messages: true

config :proca, ProcaWeb.Resolvers.ReportError,
  enable: false,
  cleartext: []

config :logger,
  level: :info

config :money,
  default_currency: :EUR

config :ecto_trail,
  table_name: "audit_log"

# ASSETS
# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.1.4",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
