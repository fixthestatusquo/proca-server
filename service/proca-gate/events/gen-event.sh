#!/bin/sh

out=$1
evn=$(basename $out)

QTD=$(cat events/amqp/$evn | sed 's/"/\\"/g'| tr '\n' ' ');
sam local generate-event sqs receive-message --body "$QTD"  > events/$evn

