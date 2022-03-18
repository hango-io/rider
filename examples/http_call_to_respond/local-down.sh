#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd ./examples/http_call_to_respond && docker-compose down
