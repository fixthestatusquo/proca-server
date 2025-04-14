import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

parse_int = fn envvar, default ->
  case System.get_env(envvar) do
    nil -> default
    limit -> String.to_integer(limit)
  end
end

config :proca, Proca.Repo,
  url: database_url,
  ssl: String.contains?(database_url, "sslmode=require"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET") || "50"),
  queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL") || "1000")

config :proca, Proca.Pipes,
  url: System.get_env("AMQP_URL") || System.get_env("CLOUDAMQP_URL") || "",
  ssl_options: [
    cacertfile: System.get_env("AMQP_CACERTFILE"),
    certfile: System.get_env("AMQP_CERTFILE"),
    keyfile: System.get_env("AMQP_KEYFILE")
  ],

  # probably a typical sec vs ms confusion
  retry_limit: parse_int.("RETRY_LIMIT", nil)

sso_home_url = System.get_env("SSO_HOME_URL")
local_auth_enable = System.get_env("LOCAL_AUTH_ENABLE", "true") == "true"

split_env = fn var, sep ->
  case System.get_env(var) do
    nil -> nil
    val when is_bitstring(val) -> String.split(val, sep)
  end
end

config :proca, ProcaWeb.UserAuth,
  local: [enabled: local_auth_enable],
  require_verified_email: is_nil(System.get_env("ALLOW_UNVERIFIED_EMAIL")),
  sso: [
    enabled: not is_nil(sso_home_url),
    home_url: sso_home_url,
    jwt_secret: System.get_env("JWT_SECRET"),
    jwks_url: System.get_env("JWKS_URL"),
    jwt: [
      email_path: split_env.("JWT_EMAIL", ~r/[,]/),
      email_verified_path: split_env.("JWT_EMAIL_VERIFIED", ~r/[,]/)
    ]
  ]

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

signing_salt =
  System.get_env("SIGNING_SALT") ||
    raise """
    environment variable SIGNING_SALT is missing.
    You can generate one by calling: mix phx.gen.secret
    """

bind_ip =
  System.get_env("LISTEN_IP", "0.0.0.0")
  |> String.split(".")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

config :proca, ProcaWeb.Endpoint,
  url: [
    host: System.get_env("DOMAIN", "localhost"),
    scheme: "https",
    port: 443
  ],
  http: [
    ip: bind_ip,
    port: String.to_integer(System.get_env("PORT", "4000"))
    # transport_options: [socket_opts: [:inet6]]
  ],
  # for WebSocket security
  check_origin: ["//" <> System.get_env("DOMAIN", "localhost")],
  allow_origin: System.get_env("CORS_ALLOW_ORIGIN", "*") |> String.split(~r/\s*,\s*/, trim: true),
  secret_key_base: secret_key_base,
  signing_salt: signing_salt

config :sentry,
  dsn: System.get_env("SENTRY_DSN")

config :proca, ProcaWeb.Resolvers.ReportError,
  enable:
    System.get_env("REPORT_USER_ERRORS") == "true" ||
      System.get_env("REPORT_AUTH_USER_ERRORS") == "true" || false,
  auth_only: System.get_env("REPORT_AUTH_USER_ERRORS") == "true" || false,
  cleartext:
    System.get_env("REPORT_USER_ERRORS_CLEARTEXT", "country,documentType,actionType")
    |> String.split(~r/\s*,\s*/, trum: true)

config :proca, ProcaWeb.Resolvers.Captcha,
  hcaptcha_key: System.get_env("HCAPTCHA_KEY"),
  captcha_service: System.get_env("CAPTCHA_SERVICE", "procaptcha")

config :proca, Proca.Service.Procaptcha, url: System.get_env("PROCAPTCHA_URL")

srs_key =
  case System.get_env("EMAIL_SRS_KEY") do
    nil ->
      random_key = :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false) |> binary_part(0, 32)
      IO.puts """
      \nWARNING ! WARNING ! WARNING !
      environment variable EMAIL_SRS_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      Using temporary random value: #{random_key}
      """
      random_key
    key -> key
  end

config :proca, Proca.Service.EmailBackend,
  srs_key: srs_key,
  srs_prefix: System.get_env("EMAIL_SRS_PREFIX", "SRS0")

config :proca, Proca,
  org_name: System.get_env("ORG_NAME", "instance"),
  stats_sync_interval: String.to_integer(System.get_env("SYNC_INTERVAL", "60000")),
  process_old_interval: String.to_integer(System.get_env("PROCESS_OLD_INTERVAL", "30000"))

config :proca, Proca.Supporter, fpr_seed: System.get_env("FINGERPRINT_SEED", "")

config :proca, Proca.Server.MTTWorker,
  max_messages_per_cycle: String.to_integer(System.get_env("MAX_MESSAGES_PER_CYCLE", "99"))

config :proca, ProcaWeb.Telemetry,
  enable: System.get_env("ENABLE_TELEMETRY", "true") == "true",
  port: String.to_integer(System.get_env("METRICS_PORT", "9568"))

# Configures Elixir's Logger
config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}, {LoggerFileBackend, :audit_log}],
  format: "$date $time $metadata[$level] $message\n",
  level:
    System.get_env("LOG_LEVEL", "error")
    |> String.to_existing_atom()

config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  level: :info,
  metadata: [:request_id]

config :logger, :error_log,
  format: "$date $time $metadata[$level] $message\n",
  path: System.get_env("LOGS_DIR", ".") <> "/error.log",
  level: :error,
  metadata: [:request_id]

config :logger, :audit_log,
  path: System.get_env("LOGS_DIR", ".") <> "/audit.log",
  level: :info,
  format: "$date $time [$level] $metadata $message\n",
  metadata: [:user, :op],
  metadata_filter: [audit: true]
