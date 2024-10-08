#!/bin/bash 

set -u 
set -e 

FUNCTION=$1
ARCHIVE=$2
CONFIG=$3


(
  rm -f $ARCHIVE.zip
  cd .aws-sam/build/$ARCHIVE
  zip -r "../../../$ARCHIVE.zip" .
)

# aws s3 cp $ARCHIVE.zip s3://$UPLOAD_BUCKET/$ARCHIVE.zip

aws lambda update-function-code --function-name $FUNCTION \
  --zip-file fileb://$ARCHIVE.zip

VARS=$(jq ".${ARCHIVE}" $CONFIG)

aws lambda update-function-configuration --function-name $FUNCTION \
  "--environment={ \"Variables\": $VARS }"

