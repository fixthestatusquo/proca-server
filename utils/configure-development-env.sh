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

sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS citext;"

# Drop databases if you want a clean start (optional)
# sudo -u postgres dropdb --if-exists proca
# sudo -u postgres dropdb --if-exists proca_test

# Create databases (will do nothing if they exist)
sudo -u postgres createdb --if-not-exists proca
sudo -u postgres createdb --if-not-exists proca_test

# Create role if it does not exist
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='proca'" | grep -q 1 || \
sudo -u postgres psql -c "CREATE ROLE proca WITH LOGIN PASSWORD 'proca';"

# Grant privileges on databases
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE proca TO proca;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE proca_test TO proca;"

# Grant privileges on schema public for both DBs
for db in proca proca_test; do
  sudo -u postgres psql -d $db -c "GRANT ALL PRIVILEGES ON SCHEMA public TO proca;"
  sudo -u postgres psql -d $db -c "CREATE EXTENSION IF NOT EXISTS citext;"  # ensure citext in each DB
done

echo "Postgres setup completed successfully."

echo " ==== Installing up RabbitMQ  dependencies  =========== "

$(dirname "$0")/configure-rabbitmq-develop.sh

echo " ==== Configuring RabbitMQ for development user   =========== "

$(dirname "$0")/configure-rabbitmq.sh

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
