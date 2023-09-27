export ACTION_IMAGE_NAME := env_var_or_default('ACTION_IMAGE_NAME', "base-action")

_default:
  @just --list

build:
  make build

# hadolint the Dockerfile
lint:
  @docker pull hadolint/hadolint
  @docker run --rm -i hadolint/hadolint < Dockerfile

test: build
  #!/bin/bash
  set -euxo pipefail

  if test -t 0
  then
    export RUN_ARGS=-it
  else
    export RUN_ARGS=
  fi
  docker run $RUN_ARGS --rm -v {{justfile_directory()}}:/tests -w /tests $ACTION_IMAGE_NAME:20.04 ./tests.sh
  docker run $RUN_ARGS --rm -v {{justfile_directory()}}:/tests -w /tests $ACTION_IMAGE_NAME:22.04 ./tests.sh
  ./check.sh
