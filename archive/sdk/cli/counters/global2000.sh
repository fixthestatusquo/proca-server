#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact
[ -z $1 ] && echo "id missing" && exit 1
#https://avaaz.org/act/frontend_api/legacy/counter.php?type=sign&cid=43504
IFS='/' read -ra SLUG <<< "$1"
URL=$(./bin/proca-cli page --id=$1 -o global2000 -J | jq -r .filename)

echo $URL;

echo "fetching  from the url=${URL}"
DATA=$(curl -s "https://$URL")
TOTAL=$( echo $DATA | jq '.pgbar.pgbar_default[0]')
echo $TOTAL

#OTHERS=$(curl -s 'https://api.proca.app/api' -H 'Content-Type: application/json'  -H 'TE: Trailers' --data-raw '{"query":"query count($campaign: String!, $org: String!) {\n  campaigns(name: $campaign) {\n    stats {\n      supporterCountByOthers(orgName: $org)\n    }\n  }\n}\n","variables":{"campaign":"keep_newgm_food_regulated_labeled","org":"global2000"},"operationName":"count"}' | jq '.data.campaigns[0].stats.supporterCountByOthers' )
OTHERS=0
COUNT=`expr $TOTAL - $OTHERS`

echo "updating $1 with total $COUNT"
./bin/proca-cli page:update --id $1 -e $COUNT
