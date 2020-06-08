# [Proca - progressive campaigning](https://proca.foundation) widget

Backend to [proca-widget](https://github.com/TechToThePeople/nodepetition).

Made with love and elixir.

Please note that this project is released with a [Contributor Code of Conduct](code_of_conduct.md). By participating in this project you agree to abide by its terms.

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md) 


# Development setup

1. Databases

```
sudo -i
su postgres
createuser -P proca
# input "proca" as password
createdb -O proca proca
createdb -O proca proca_test
exit
exit
```

2. Create RabbitMQ

```
./utils/create-queue
sudo -i
echo "172.19.0.3  rabbitmq.docker" >> /etc/hosts
```

Login to http://rabbitmq.docker:15672/ with guest/guest and add:
- virtual host called "proca" (not "/proca")
- user called proca (pass proca) with full access to virtual host "proca"

3. Init the db
```
env mix ecto.migrate
env  mix run priv/repo/seeds.exs
# same for test db
env MIX_ENV=test mix ecto.migrate
env MIX_ENV=test  mix run priv/repo/seeds.exs
```
