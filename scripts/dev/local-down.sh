#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd ./scripts/dev && docker-compose down