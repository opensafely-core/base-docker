export ACTION_IMAGE_NAME := env_var_or_default('ACTION_IMAGE_NAME', "base-action")

_default:
  @just --list

# build all images
build *args:
  #!/bin/bash
  export DOCKER_BUILDKIT=1
  export BASE_CREATED=$(date --utc +'%Y-%m-%dT%H:%M:%S+00:00')
  export BASE_GITREF=$(git rev-parse --short HEAD)
  docker compose build --pull {{ args }}

clean-build: (build "--no-cache")

# hadolint the Dockerfile
lint:
  @docker pull hadolint/hadolint
  @docker run --rm -i hadolint/hadolint < Dockerfile

# build and test all images
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
  docker run $RUN_ARGS --rm -v {{justfile_directory()}}:/tests -w /tests $ACTION_IMAGE_NAME:24.04 ./tests.sh
  ./check.sh

# Update the files tracking the SHAs of ubuntu docker image
update-docker-shas:
  @just _update-sha "ubuntu:20.04"
  @just _update-sha "ubuntu:22.04"

_update-sha os:
  echo {{ os }}
  docker image pull {{ os }}
  docker inspect --format='{{{{index .RepoDigests 0}}' {{ os }} > {{ os }}.sha
