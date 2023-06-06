# [Proca - Progressive Campaigning](https://proca.app) backend

An universal action tool backend for JAM stack apps.
Elixir app that uses PostgreSQL as data store and RabbitMQ
for data processing. It is the backend / datastore for [Proca Widget](https://github.com/FixTheStatusQuo/proca).

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

- PostgreSQL >= 10
- Elixir >= 1.14

we recommend asdf to install erlang+elixir:
in this repo, run 

    $ sudo apt install automake libssl-dev autoconf libncurses5-dev
    $asdf plugin add erlang
    $asdf plugin add elixir
    $asdf install
    $mix local.rebar 
    $mix local.hex

  You'll need the following packages:
    `erlang-base erlang-dev erlang-parsetools erlang-xmerl elixir`

- RabbitMQ (3.x, tested on 3.8)

- NodeJS (>= 14)

# Just trying out setup 

**Required:**

- docker
- docker-compose 
- proca-cli (install with: `npm i -g @proca/cli`)

If you would just like to try out proca server, it's easiest with docker-compose:

```
$ cd proca/utils
$ docker-compose up -d 
# wait until the servers start 

$ docker-compose logs proca 
# note down the username and password for the user of primary "instance" organisation. 

    $ export API_URL=http://localhost:4000
    $ proca server:add -h http://localhost -s 4000 -u {user} -p {password} localhost 

Now you can:

- Use procato talk to the server API. 
- You can also perform API calls directly using GraphQL in the [GraphQL playground](http://localhost:4000/graphiql) - it's great for exploring the API! Sign in at [http://localhost:4000](http://localhost:4000) to make authenticated API calls. 
- You can see the processing in action using [RabbitMQ management console](http://localhost:15672/) - login with user name _proca_, password _proca_.


# Development setup

The script utils/configure-development-environment.sh will setup PostgreSQL, the Erlang / Elixir / Pheonix server, the RabbitMQ server and runs npm install in the assets directory.

The script needs a few ENV varaibles set:

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

# build

    $./build

should walk you through the steps to build a prod version

# Configuration

See config/config.exs and config/dev.exs for configuration options.
