#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

BASE_ENVOY_IMAGE=${BASE_ENVOY_IMAGE:-"hangoio/envoy-proxy:v0.0.1-b9696c2"}

BASE_IMAGE=${BASE_ENVOY_IMAGE} IMAGE_TAG=rider:local-dev make build

FORCE_BUILD=0
if [[ $# -gt 0 ]]; then
    if [[ $1 == "-f" ]]; then
        FORCE_BUILD=1
    fi
fi

if [[ $FORCE_BUILD == "1" ]]; then
    docker-compose -f examples/body_to_header_to_refresh/docker-compose.yaml up --build
else
    docker-compose -f examples/body_to_header_to_refresh/docker-compose.yaml up  
fi
