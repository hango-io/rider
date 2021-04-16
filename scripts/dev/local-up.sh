#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

BASE_ENVOY_IMAGE=${BASE_ENVOY_IMAGE:-"hub.c.163.com/qingzhou/gateway-proxy:ci-61e1518f"}

BASE_IMAGE=${BASE_ENVOY_IMAGE} IMAGE_TAG=aggra:local-dev make build

cd ./scripts/dev && docker-compose up --build
