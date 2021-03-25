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


# Development setup

Proca backend is an Elixir app that uses PostgreSQL as data store and RabbitMQ
for data processing. The PostgreSQL is managed by migrations. The RabbitMQ is
(re)configured live when the app is run, it only needs predentials to access it.

1. Databases: create

```
sudo -i
su postgres
createuser -P proca
# input "proca" as password
createdb -O proca proca
createdb -O proca proca_test
exit
```

3. Databases: initialize
```
mix ecto.migrate
mix run priv/repo/seeds.exs
# same for test db
env MIX_ENV=test mix ecto.migrate
env MIX_ENV=test  mix run priv/repo/seeds.exs
```

3. Create RabbitMQ

```
./utils/create-queue
sudo -i
echo "172.19.0.3  rabbitmq.docker" >> /etc/hosts
# add proca user and proca vhost
./utils/create-queue-creds
```

Login to http://rabbitmq.docker:15672/ with guest/guest and add:
- virtual host called "proca" (not "/proca")
- user called proca (pass proca) with full access to virtual host "proca"

Test vhost: we do not use a test vhost at this point. The test run uses the same
dev one (should be moved to test one at some point, or queue messaging mocked
out).

4. Run the app

```
mix deps.get
mix phx.server
```
