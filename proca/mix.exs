defmodule Proca.MixProject do
  use Mix.Project

  def project do
    [
      app: :proca,
      version: "0.2.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      releases: [
        proca: [
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Proca.Application, []},
      extra_applications: [:logger, :runtime_tools, :absinthe_plug]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.0"},
      {:phoenix_pubsub, "~> 2.0", override: true}, # See below
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:ecto_enum, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.2"},
      {:sentry, "~> 7.0"},
      {:plug_cowboy, "~> 2.3"},
      {:absinthe, "1.5.0-rc.0"},
      {:absinthe_phoenix, "~> 1.5.0-rc.0"},
      {:absinthe_plug, "~> 1.5.0-rc.0"},
      {:cors_plug, "~> 2.0"},
      {:kcl, "~> 1.3.0"},
      {:amqp, "~> 1.4"},
      {:broadway_rabbitmq, "~> 0.6.1"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_ses, "~> 2.1"},
      {:ex_aws_sqs, "~> 3.2"},
      {:hackney, "~> 1.16.0"},
      {:sweet_xml, "~> 0.6"},
      {:json, "~> 1.3.0"},  # XXX migrate to jason
      {:poison, "~> 4.0"},
      {:phoenix_live_view, "~> 0.12.1"},
      {:pow, "~> 1.0.20"},
      {:proper_case, "~> 1.0.2"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:logger_file_backend, "~> 0.0.11"},
      {:mix_systemd, "~> 0.7.3"},
      {:floki, ">= 0.0.0", only: :test},
      {:ex_machina, "~> 2.4", only: :test},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dogma, "~> 0.1", only: [:dev]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  # Phoenix 1.5 update
  #
  # At the time of writing absinthe is still at 1.5-RC.X stage, and it did not
  # start using upgraded phoenix_pubsub (still requires 1.x, Phx 1.5 needs 2.x)
  # Here's a relevant PR:
  # https://github.com/absinthe-graphql/absinthe_phoenix/pull/68
  #
  # I am adding override: true because we do not use subscriptions in Absinthe
  # and even now the Pubsub subsystem of Absinthe was not started.
  #
  # TODO: Keep track of absinthe dev to remove the -rc.0 postfix from versions
  # when it's ready
  #
  # absinthe_ecto was deprecated by Dataloader.Ecto from the dataloader package
  # instead.

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "assets/static/images/proca-logo.png",
      extras: [
        "README.md",
        "code_of_conduct.md"
      ] ++ Path.wildcard("guides/*.md"),
      extra_section: "Guides"
    ]
      # Example from broadway:
      # groups_for_extras: [
      #   Examples: Path.wildcard("guides/examples/*.md"),
      #   Internals: Path.wildcard("guides/internals/*.md")
      # ],
      # groups_for_modules: [
      #   Acknowledgement: [
      #     Broadway.Acknowledger,
      #     Broadway.CallerAcknowledger,
      #     Broadway.NoopAcknowledger
      #   ],
      #   Producers: [
      #     Broadway.DummyProducer,
      #     Broadway.TermStorage
      #   ]
  end
end
