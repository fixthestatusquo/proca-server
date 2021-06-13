#!/bin/bash

set -e 
set -u 

echo Adding codegen to current project
curdir=$(dirname $0)

cp -v $curdir/codegen.yml .

yarn add -D \
graphql@15.3.0 \
@graphql-codegen/cli \
@graphql-codegen/typed-document-node \
@graphql-codegen/typescript \
@graphql-codegen/typescript-operations 

# not used any more
# @graphql-codegen/import-types-preset \
# @graphql-codegen/introspection \
# @graphql-codegen/add \
# @graphql-codegen/typescript-graphql-request



