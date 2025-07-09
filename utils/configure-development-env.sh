#!/bin/sh

# set -e

echo <<INTRO
============ Configuring Development Environment =====================

    We'll configure PostgreSQL, RabbitMQ
    and setup the Elixir environment.

    If anything goes wrong, we'll give up.

======================================================================
INTRO


echo " ==== Initializing PostgreSQL =========== "

sudo -u postgres psql template1 -c 'create extension if not exists citext;'
sudo -u postgres createdb proca;
sudo -u postgres createdb proca_test;
sudo -u postgres psql -c "
create role proca with login password 'proca';
grant all privileges on database proca to proca;
grant all privileges on database proca_test to proca;
GRANT ALL ON SCHEMA public TO proca;
GRANT ALL ON SCHEMA public TO proca;
"

echo " ==== Installing up RabbitMQ  dependencies  =========== "

./utils/configure-rabbitmq-develop.sh

echo " ==== Configuring RabbitMQ for development user   =========== "

./utils/configure-rabbitmq.sh

echo " ==== Running npm install in assets ==== "

(cd assets/ && npm install)

echo " ==== Setting up Elixir      =========== "

mix deps.get
mix ecto.migrate --quiet
# same for test db
env MIX_ENV=test mix ecto.migrate --quiet

if [ -z "${ADMIN_EMAIL}" ]; then
    # Prompt user to input the email address
    echo "⚠️ ADMIN_EMAIL environment variable is required, but not set."
    read -p "Please enter your admin email address: " ADMIN_EMAIL
    # Export it to make it available to seeds.exs
    export ADMIN_EMAIL
    echo "ADMIN_EMAIL env set to: ${ADMIN_EMAIL}"
fi

# Run seeds last so passwords are not lost
env MIX_ENV=test mix run priv/repo/seeds.exs
mix run priv/repo/seeds.exs