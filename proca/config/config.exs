# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

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
  sso: [
    enabled: false,
    home_url: "https://account.fixthestatusquo.org"
    # login_url: ,
    # register_url: "",
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
  require_verified_email: false,
  start_daemon_servers: true

# FPR seed only for development
config :proca, Proca.Supporter, fpr_seed: "4xFc6MsafPEwc6ME"

config :proca, Proca.Pipes,
  url: "amqp://proca:proca@localhost/proca",
  ssl_options: nil

config :proca, Proca.Server.Jwks, url: "https://account.fixthestatusquo.org/.well-known/jwks.json"

# Disable lager logging (included by rabbitmq app)
config :lager, handlers: []

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 10_000

config :ex_aws_sqs, parser: ExAws.SQS.SweetXmlParser

config :sentry,
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  capture_log_messages: true

config :proca, ProcaWeb.Resolvers.ReportError, enable: false

config :logger,
  level: :info

config :money,
  default_currency: :EUR

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
