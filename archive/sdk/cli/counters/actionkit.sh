#!/usr/bin/bash
##Keep New GM-Food strictly regulated and labeled!
URL="act.pollinis.org/progress/?page=petition-europeenne-ogm-fr"
ID=1022
echo "fetching  from the url=${URL}"
DATA=$(curl -s "https://$URL")
length=${#DATA}
DATA="${DATA:33:length-34}"
echo $DATA
TOTAL=$( echo $DATA | jq '.total.actions')
echo $TOTAL
./bin/proca-cli page:update --id $ID -e $TOTAL
