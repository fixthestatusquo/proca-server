#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact
[ -z $1 ] && echo "slug missing" && exit 1
echo "fetching  from the slug $1"
DATA=$(curl -s https://www.campact.de/api/metrics/v1/r/$1)
PARTNER=$( echo $DATA | jq '.c["participate/partner"]')
TOTAL=$( echo $DATA | jq .t.participate)
CAMPACT=`expr $TOTAL - $PARTNER`
ID=$(./bin/proca-cli page -P -J --name aktion.campact.de/$1 | jq .actionpage)
echo "updating $ID with total $CAMPACT"
./bin/proca-cli page:update --id $ID -e $CAMPACT
