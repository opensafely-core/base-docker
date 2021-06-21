BASE_IMAGE_NAME ?= base-docker
ACTION_IMAGE_NAME ?= base-action
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
export DOCKER_BUILDKIT=1

.PHONY: build-base
build-base: BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
build-base: GITREF=$(shell git rev-parse --short HEAD)
build-base:
	docker build . --tag $(BASE_IMAGE_NAME) --target base-docker \
		--build-arg BUILDKIT_INLINE_CACHE=1 --cache-from ghcr.io/opensafely-core/base-docker \
		--build-arg BASE_BUILD_DATE=$(BUILD_DATE) --build-arg BASE_GITREF=$(GITREF) $(ARGS)

.PHONY: build-action
build-action:
	docker build . --tag $(ACTION_IMAGE_NAME) --target base-action \
		--build-arg BUILDKIT_INLINE_CACHE=1 --cache-from ghcr.io/opensafely-core/base-action $(ARGS)

.PHONY: build
build: build-base build-action

.PHONY: clean-build
clean-build: ARGS=--no-cache
clean-build: build-base build-action


.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test:
	docker run $(RUN_ARGS) --rm -v $(PWD):/tests -w /tests $(ACTION_IMAGE_NAME) ./tests.sh


.PHONY: lint
lint:
	@docker pull hadolint/hadolint
	@docker run --rm -i hadolint/hadolint < Dockerfile
