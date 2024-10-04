#!/bin/bash 

set -u 
set -e 

ARCHIVE=$1


(
  rm -f $ARCHIVE.zip
  cd .aws-sam/build/$ARCHIVE
  zip -r "../../../$ARCHIVE.zip" .
)

aws s3 cp $ARCHIVE.zip s3://$UPLOAD_BUCKET/$ARCHIVE.zip

aws lambda publish-layer-version \
  --layer-name $ARCHIVE \
  --compatible-runtimes    nodejs12.x \
  --content "S3Bucket=$UPLOAD_BUCKET,S3Key=$ARCHIVE.zip"
