#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

mix version "${1:---patch}"
NEW_VERSION=$(mix version --info 2>/dev/null)

echo " New version released: ${NEW_VERSION}"
git push origin "${NEW_VERSION}"
