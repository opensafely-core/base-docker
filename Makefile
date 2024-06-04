BASE_IMAGE_NAME ?= base-docker

export DOCKER_BUILDKIT=1
export BASE_BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
export BASE_GITREF=$(shell git rev-parse --short HEAD)


build:
	docker compose build --pull $(ARGS)

clean-build: ARGS=--no-cache
clean-build: build
