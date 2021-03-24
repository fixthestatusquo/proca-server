#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact
[ -z $1 ] && echo "slug missing" && exit 1
echo "fetching  from the key: $1"
#https://www.umweltinstitut.org/apps/stats/?aktion=68


IFS='/' read -ra SLUG <<< "$1"
DATA=$(curl -s "https://www.foodwatch.org/de/startseite/?type=5000&ncv=1&tx_wwt3foodwatch_sharedcounterapi%5bapiKey%5d=0d72c27e-7c79-6a28-99c8-30d1262b1f25&tx_wwt3foodwatch_sharedcounterapi%5bexcludeSelf%5d=1&tx_wwt3foodwatch_sharedcounterapi%5baction%5d=getCounter&tx_wwt3foodwatch_sharedcounterapi%5bcontroller%5d=SharedCounterApi")
COUNT=$( echo $DATA | jq '.count')
ID=$(./bin/proca-cli page -P -J --name $1 | jq .actionpage)
echo "updating $ID with total $COUNT"
./bin/proca-cli page:update --id $ID -e $COUNT
