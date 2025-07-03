#!/bin/bash 
# usage: ./counter/campact [slug of the campact campaign]
# it assumes that there is an action page with the aktion.campact.de/[slug] already defined
# can be used in a cron for automatically updating the counter on proca for campaigns that partner with campact
[ -z $1 ] && echo "slug missing" && exit 1
#https://avaaz.org/act/frontend_api/legacy/counter.php?type=sign&cid=43504
IFS='/' read -ra SLUG <<< "$1"
echo "fetching  from the cid=${SLUG[1]}"
DATA=$(curl -s 'https://avaaz.org/act/frontend_api/legacy/counter.php?type=sign&cid=43504' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Cookie: __cfduid=dc076253c8840f6fbefb7b9da5c17c2651614268375; avz_session=tkiust3ihhb30mv9a24dna56ae6k0kqv' -H 'Upgrade-Insecure-Requests: 1' -H 'If-Modified-Since: Sun, 28 Feb 2021 18:41:26 GMT' -H 'Cache-Control: max-age=0' -H 'TE: Trailers')
TOTAL=$( echo $DATA | jq '.count')
OTHERS=$(curl -s 'https://api.proca.app/api' -H 'Content-Type: application/json'  -H 'TE: Trailers' --data-raw '{"query":"query count($campaign: String!, $org: String!) {\n  campaigns(name: $campaign) {\n    stats {\n      supporterCountByOthers(orgName: $org)\n    }\n  }\n}\n","variables":{"campaign":"ect","org":"avaaz"},"operationName":"count"}' | jq '.data.campaigns[0].stats.supporterCountByOthers' )

COUNT=`expr $TOTAL - $OTHERS`

ID=$(./bin/proca-cli page -P -J --name $1 | jq .actionpage)
echo "updating $ID with total $COUNT"
./bin/proca-cli page:update --id $ID -e $COUNT
