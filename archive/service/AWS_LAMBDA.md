# Running on AWS Lambda 

## tooling help

To avoid some painpoints of working with AWS Lambda I am using:

- AWS SAM CLI (pip3 install aws-sam-cli)
- Typescript


I found this article very helpful: https://evilmartians.com/chronicles/serverless-typescript-a-complete-setup-for-aws-sam-lambda

## Building

- Build everything: `sam build` (uses Makefile)
- Build just one of Makefile targets: make build-IdentitySync (export ARTIFACT_DIR=.aws-sam/build/IdentitySync)

## Develop
To run locally with SQS event: `sam local invoke -n ./env.json -e events/register.json  IdentitySync` 

To create an test SQS event put Proca action message into `events/amqp/foo.json` and run `./events/gen-event.sh foo.json` to get SQS event with that payload.

To debug using Chrome Developer Tools: 

1. Run with `-d port`: `sam local invoke ... -d 12345`. 
2. Open chrome://inspect in Chormium, Click "Configure" and add localhost:12345 there
3. Click "inspect" link under Remote Target.

# Deployment
