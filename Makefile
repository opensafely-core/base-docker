BASE_IMAGE_NAME ?= base-docker

export DOCKER_BUILDKIT=1
export BASE_BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
export BASE_GITREF=$(shell git rev-parse --short HEAD)


build:
	docker-compose build --pull $(ARGS) base-docker-20.04 base-docker-22.04 base-action-20.04 base-action-22.04

clean-build: ARGS=--no-cache
clean-build: build
