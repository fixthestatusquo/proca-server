#!/bin/bash

set -e
set -u

#
# XXX: this is for communicating between docker containers, the container below listens on localhost:15672
#
# docker network create --subnet=172.19.0.0/16 proca || echo "Ok, virtual network 'proca' already exists"
#

VOL=/tmp/proca-queuestart
URL=http://localhost:15672/api

mkdir $VOL || true

echo "--- starting rabbitmq as docker container ------------"
docker run --detach -p 5672:5672 -p 15672:15672  \
    -v $VOL:/var/lib/rabbitmq --name rabbitmq    \
    rabbitmq:3-management || if [[ $? = 125 ]]; then echo "Already created"; docker start rabbitmq;  else exit 1; fi



rabbitmq()
{
    curl -u guest:guest -H "content-type:application/json" "$@"
}

echo "--- waiting for rabbitmq management to wake up ---"
while ! rabbitmq $URL/vhosts 2>/dev/null >/dev/null; do sleep 0.5; done

echo "--- creating proca user -------------------------------"

rabbitmq -XPUT $URL/vhosts/proca
rabbitmq -d '{"password":"proca", "tags":""}' -XPUT $URL/users/proca 
rabbitmq -d '{"configure":".*","write":".*","read":".*"}' -XPUT $URL/permissions/proca/proca


