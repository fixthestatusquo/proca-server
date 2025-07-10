# [Proca - Progressive Campaigning](https://proca.app) backend

An universal action tool backend for JAM stack apps.
Elixir app that uses PostgreSQL as data store and RabbitMQ
for data processing. It is the backend / datastore for [Proca Widget](https://github.com/FixTheStatusQuo/proca).

Proca Server is a (mostly headless) [Phoenix App](https://www.phoenixframework.org/) so learn about how to work with such apps. Proca uses all standard mechanisms and practices of Phoenix Framework!

It is made with love, elixir and hope we can change the world for the better.

Please note that this project is released with a [Contributor Code of Conduct](code_of_conduct.md). By participating in this project you agree to abide by its terms.

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

## Features

- Headless 
- GraphQL API 
- Fine grained permission system for users organised in Organisatons (Orgs)
- Authentication using HTTP Basic Auth or JWT (to use external identity and auth system).
- Stores campaign tree (action pages organised in campaigns, where different Orgs can run a coalition)
- Stores actions and member personal data, personal data is E2E encrypted at rest. Only the Org that is data controller can decrypt it.
- Validates personal data types using various personal data schemas (email+postcode, European Citizen Initaitive, and so on)
- Handles GDPR consent (with optional double opt-in), and action staging (moderation, filtering before it is accepted)
- Sends emails (thank you emails, opt in emails, emails-to-targets) through various mail backends (Mailjet, AWS SES, more coming)
- Pluggable action processing on RabbitMQ queue 
- Forward actions to AWS SQS, CRMs (needs a decrypting gateway proxy at Org premises)
- Export action data in CSV


# Prerequisites

To develop and run proca server, these are needed:

- PostgreSQL >= 10
  This is a db server

- Elixir >= 1.14 

we [recommend asdf](https://asdf-vm.com/guide/getting-started.html) to install erlang+elixir

in this repo, run 

    $ sudo apt install automake libssl-dev autoconf libncurses5-dev
    $ asdf plugin add erlang
    $ asdf plugin add elixir
    $ asdf install
    $ mix local.rebar 
    $ mix local.hex

  You'll need the following packages:
    `erlang-base erlang-dev erlang-parsetools erlang-xmerl elixir`

- RabbitMQ (3.x, tested on 3.8)

  This is a queue server

- NodeJS (>= 14)
  Node is not needed on server where we deploy bundled assets.

# Development setup

The script utils/configure-development-environment.sh will setup PostgreSQL, the Erlang / Elixir / Pheonix server, the RabbitMQ server and runs npm install in the assets directory.

Make sure PostgreSQL and RabbitMQ are installed

The script needs a few ENV variables set:

`$ export ADMIN_EMAIL=you@example.com MIX_ENV=dev ORGANISATION='fix-the-status-quo'`

You'll need sudo to run the parts of the script that configure PostgreSQL.

`$ ./utils/configure-development-environment.sh`

The seeds.exs command will print out your login and password:

    #####
    #####   Created Admin user email@example.com  #####
    #####   Password: VERY_RANDOM_PASSWORD
    #####

You can then run the development server.

`$ mix phx.server`

By default, the development webserver is located at http://localhost:4000/

# From building to server

This is a [must read on development of Phoenix apps](https://hexdocs.pm/phoenix/up_and_running.html)

This is a [must read on deployment of Phoenix apps](https://hexdocs.pm/phoenix/deployment.html).

    $./build

Read more in [Developing](guides/Developing).

# Using docker to just try out Proca (NOT UP TO DATE!)

If you would just like to try out proca server, it's easiest with docker-compose. It will create proca, along with postgres and rabbitmq containers.

**Required:**

- docker
- docker-compose 
- proca cli (install with: `pip install proca`)


```
$ pip install proca # install CLI
$ cd proca/utils
$ docker-compose up -d 
# wait until the servers start 

$ docker-compose logs proca 
# note down the username and password for the user of primary "instance" organisation. 

$ proca server:add local
API url: http://localhost:4000
🍦 API url looks ok - http://localhost:4000/api 
API token []: (RETURN)
sername (email): some@example.com
Password: 
Repeat for confirmation: 
(it will create a token and store in ~/.config/proca/proca.conf)
$
```

Now you can:

- Use proca CLI to talk to the server API. 
- You can also perform API calls directly using GraphQL in the [GraphQL playground](http://localhost:4000/graphiql) - it's great for exploring the API! Sign in at [http://localhost:4000](http://localhost:4000) to make authenticated API calls. 
- To use the GraphiQL API with a token you have set up in proca CLI, type `proca token` and put the `Bearer sometoken` into `Authorization` header in GraphiQL bottom screen. 
- You can see the processing in action using [RabbitMQ management console](http://localhost:15672/) - login with user name _proca_, password _proca_.


# Configuration

This is standard [Phoenix Framework](https://hexdocs.pm/phoenix/overview.html), which knowledge is absolutely mandatory.

Phoenix apps use configuration in `config/config.exs` which then is overriden by files depending on `MIX_ENV` (similar to `NODE_ENV`), respectively: dev, prod, test. The `config/releases.exs` runs in prod and will read environment variables *from the server*. The `prod.exs` will read environment variables on compile time (your dev laptop) and hardcode them inside elixir bytecode. This is a legacy of Erlang deployment strategies.

See config/config.exs and config/dev.exs for configuration options.

The config files set a settings tree, read it like so:

- Configures proca server, in particular the `ProcaWeb.Resolvers.ReportError` module, and sets two keys: `enable` and `cleartext`.

```elixir
config :proca, ProcaWeb.Resolvers.ReportError,
  enable: false,
  cleartext: []
```

- Configures other bundled apps (here: Sentry client):

``` elixir
config :sentry,
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  capture_log_messages: true
```

Also for development purposes you can use some env variables to change the server behaviour:

- `ENABLE_TELEMETRY` if set to `true` the server will serve prometheus metrics on port 9568. Enabled by default, disable it by setting `export ENABLE_TELEMETRY=false`
- `START_DAEMON_SERVERS` if set to `true` the server will start some processes in the background. Disable it to make the development server starts faster when you are not working on MTT. Enabled by default, disable it by setting `export START_DAEMON_SERVERS=false`
