#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact
[ -z $1 ] && echo "slug missing" && exit 1
echo "fetching  from the aktion/id: $1"
#https://www.umweltinstitut.org/apps/stats/?aktion=68


IFS='/' read -ra SLUG <<< "$1"
DATA=$(curl -s https://www.umweltinstitut.org/apps/stats/?aktion=${SLUG[1]})
COUNT=$( echo $DATA | jq '.nettocount')
ID=$(./bin/proca-cli page -P -J --name $1 | jq .actionpage)
echo "updating $ID with total $COUNT"
./bin/proca-cli page:update --id $ID -e $COUNT
