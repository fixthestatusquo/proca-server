#!/bin/bash

set -e 
set -u 

echo Adding codegen to current project
curdir=$(dirname $0)

if [ -f $curdir/codegen.yml ]; then
    cp -v $curdir/codegen.yml .
else
    cp -v node_modules/@proca/api/codegen/codegen.yml .
fi

yarn add -D \
graphql@15.3.0 \
@graphql-codegen/cli \
@graphql-codegen/typed-document-node \
@graphql-codegen/typescript \
@graphql-codegen/typescript-operations \
codegen-graphql-scalar-locations


yarn add \
urql-serialize-scalars-exchange

# not used any more
# @graphql-codegen/import-types-preset \
# @graphql-codegen/introspection \
# @graphql-codegen/add \
# @graphql-codegen/typescript-graphql-request



