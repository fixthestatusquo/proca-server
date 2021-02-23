#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact

[ -z $1 ] && echo "slug missing" && exit 1
[ -z $2 ] && echo "speakout instance missing" && exit 1

echo "fetching  from the $2 with slug $1"
DATA=$(curl -s https://$2/$1.json)
TOTAL=$( echo $DATA | jq '.uniquersigns')
ID=$(./bin/proca-cli page -P -J --name $1 | jq .actionpage)
echo "updating $ID with total $TOTAL"
./bin/proca-cli page:update --id $ID -e $CAMPACT
