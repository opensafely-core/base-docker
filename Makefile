IMAGE_NAME ?= base-docker-test
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

.PHONY: build
build:
	docker build . --tag $(IMAGE_NAME) 

.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test:
	docker run $(RUN_ARGS) --rm -v $(PWD):/tests -w /tests $(IMAGE_NAME) ./tests.sh
