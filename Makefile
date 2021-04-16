IMAGE_TAG_SUFFIX ?=${shell date +"%Y%m%d%H%M%S"}
COMMIT := $(shell git rev-parse --short HEAD)
IMAGE_TAG ?= envoy-lua:${COMMIT}-${IMAGE_TAG_SUFFIX}

BASE_IMAGE ?= BASE_IMAGE

build:
	docker build --build-arg BASE_IMAGE=${BASE_IMAGE} -t ${IMAGE_TAG} .
