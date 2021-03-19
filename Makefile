IMAGE_NAME ?= base-docker-test
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
export DOCKER_BUILDKIT=1

.PHONY: build
build: BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
build: GITREF=$(shell git rev-parse --short HEAD)
build:
	docker build . --tag $(IMAGE_NAME) \
		--build-arg BUILDKIT_INLINE_CACHE=1 --cache-from ghcr.io/opensafely-core/base-docker \
		--build-arg BASE_BUILD_DATE=$(BUILD_DATE) --build-arg BASE_GITREF=$(GITREF)

.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test:
	docker run $(RUN_ARGS) --rm -v $(PWD):/tests -w /tests $(IMAGE_NAME) ./tests.sh
