#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Please checkout 'main' branch"
    exit 1
fi

GIT_STATUS=$(git status --short)
if [ -n "$GIT_STATUS" ]; then
    echo "Please commit your changes"
    echo "$GIT_STATUS"
    exit 1
fi

mix version "${1:---patch}"
NEW_VERSION=$(mix version --info 2>/dev/null)

echo " New version released: ${NEW_VERSION}"
git push origin main
git push origin "${NEW_VERSION}"
