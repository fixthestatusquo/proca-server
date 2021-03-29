# [Proca - Progressive Campaigning](https://proca.app) backend

An universal action tool backend for JAM stack apps.
Built as a backend to [Proca Widget](https://github.com/FixTheStatusQuo/proca).

Made with love and elixir.

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

PostgreSQL >= 10

Elixir >= 1.10

    $ mix deps.get / compile
    /usr/lib/erlang/lib/parsetools-2.2/include/yeccpre.hrl: no such file or directory

    Install erlang-dev and erlang-parsetools packages.

    $ mix phx.server
    [error] calling logger:remove_handler(default) failed: :error {:badmatch, {:error, {:not_found, :default}}}
    ** (Mix) Could not start application xmerl: could not find application file: xmerl.app

    Install erlang-xmerl

RabbitMQ (version?)

NodeJS (>= 10?) / npm >= 7?

# Development setup

Proca backend is an Elixir app that uses PostgreSQL as data store and RabbitMQ
for data processing.

The script utils/configure-development-environment.sh will setup PostgreSQL, the Erlang / Elixir / Pheonix server, the RabbitMQ server and runs npm install in the assets directory.

You'll need sudo to run the parts of the script that configure PostgreSQL.

$ ./utils/configure-development-environment.sh

If things go wrong, you can refer to the script for the details of installing and configuring each piece.

Once the installation / configuration is complete you can run the development app:

```
mix phx.server
```
