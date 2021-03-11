#!/bin/sh

# set -e

echo <<INTRO
============ COnfiguring Development Environment ===================== 

       We'll configure PostgreSQL, RabbitMQ 
       and setup the Elixir environment.    

       If anything goes wrong, we'll give up.    

======================================================================
INTRO


echo " ==== Initializing PostgrSQL =========== "

sudo -u postgres psql template1 -c 'create extension if not exists citext;'
sudo -u postgres createdb proca;
sudo -u postgres createdb proca_test;
sudo -u postgres psql -c "
create role proca with login password 'proca'; 
grant all privileges on database proca to proca;
grant all privileges on database proca_test to proca;
"

echo " ==== Setting up RabbitMQ    =========== "

./utils/configure-rabbitmq


echo " ==== Setting up Elixir      =========== "

mix deps.get
mix ecto.migrate --quiet 

# same for test db
env MIX_ENV=test mix ecto.migrate --quiet
env MIX_ENV=test mix run priv/repo/seeds.exs

mix run priv/repo/seeds.exs

echo " ==== Running npm install in assets ==== "

(cd assets/ && npm install)
