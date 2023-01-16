BASE_IMAGE_NAME ?= base-docker
ACTION_IMAGE_NAME ?= base-action
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)


export DOCKER_BUILDKIT=1
export BASE_BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
export BASE_GITREF=$(shell git rev-parse --short HEAD)


build:
	docker-compose build --pull $(ARGS) base-docker-20.04 base-docker-22.04 base-action

clean-build: ARGS=--no-cache
clean-build: build


.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test:
	docker run $(RUN_ARGS) --rm -v $(PWD):/tests -w /tests $(ACTION_IMAGE_NAME):20.04 ./tests.sh
	./check.sh

.PHONY: lint
lint:
	@docker pull hadolint/hadolint
	@docker run --rm -i hadolint/hadolint < Dockerfile
