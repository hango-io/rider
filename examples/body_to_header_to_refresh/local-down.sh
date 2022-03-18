#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd ./examples/body_to_header_to_refresh && docker-compose down
