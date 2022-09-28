BASE_IMAGE_NAME ?= base-docker
ACTION_IMAGE_NAME ?= base-action
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
export DOCKER_BUILDKIT=1

.PHONY: build-base
build-base:
	$(MAKE) build-version UBUNTU_VERSION=20.04 ARGS=$(ARGS)
	docker tag $(BASE_IMAGE_NAME):20.04 $(BASE_IMAGE_NAME):latest
	$(MAKE) build-version UBUNTU_VERSION=22.04 ARGS=$(ARGS)


build-version: BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
build-version: GITREF=$(shell git rev-parse --short HEAD)
build-version: UBUNTU_VERSION ?= 20.04
build-version:
	docker build . --pull --target base-docker \
		--build-arg UBUNTU_IMAGE=ubuntu:$(UBUNTU_VERSION) --tag $(BASE_IMAGE_NAME):$(UBUNTU_VERSION) \
		--build-arg BUILDKIT_INLINE_CACHE=1 --cache-from ghcr.io/opensafely-core/base-docker \
		--build-arg BASE_BUILD_DATE=$(BUILD_DATE) --build-arg BASE_GITREF=$(GITREF) $(ARGS)


.PHONY: build-action
build-action:
	docker build . --tag $(ACTION_IMAGE_NAME) --tag $(ACTION_IMAGE_NAME):20.04 --target base-action \
		--build-arg UBUNTU_IMAGE=ubuntu:20.04 \
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
