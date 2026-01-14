set dotenv-load := true

export ACTION_IMAGE_NAME := env_var_or_default('ACTION_IMAGE_NAME', "base-action")
export UBUNTU_PRO_TOKEN_FILE := env_var_or_default('UBUNTU_PRO_TOKEN_FILE', justfile_directory() + "/.secrets/ubuntu_pro_token")

_default:
  @just --list

ensure-pro-token:
  #!/bin/bash
  set -euo pipefail
  token_file="{{ UBUNTU_PRO_TOKEN_FILE }}"
  if test -z "${UBUNTU_PRO_TOKEN:-}"; then
    echo "UBUNTU_PRO_TOKEN is required to create $token_file" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$token_file")"
  umask 077
  printf '%s' "$UBUNTU_PRO_TOKEN" > "$token_file"

# build all images
build *args: ensure-pro-token
  #!/bin/bash
  set -euo pipefail
  export DOCKER_BUILDKIT=1
  export BASE_CREATED=$(date --utc +'%Y-%m-%dT%H:%M:%S+00:00')
  export BASE_GITREF=$(git rev-parse --short HEAD)
  docker compose build --pull {{ args }}

clean-build: (build "--no-cache")

# hadolint the Dockerfile
lint:
  @docker run --rm -i hadolint/hadolint < Dockerfile
  @ls *.sh | xargs docker run --rm -v "$PWD:/mnt:ro" koalaman/shellcheck:v0.11.0
  @docker run --rm -v "$PWD:/repo:ro" --workdir /repo rhysd/actionlint:1.7.10 -color

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


publish-images:
  #!/bin/bash
  set -euo pipefail
  for version in 20.04 22.04 24.04
  do 
      for image_name in base-docker base-action
      do
        image="$image_name:$version"
        full="ghcr.io/opensafely-core/$image"
        docker tag $image $full
        docker push $full
      done
  done

  # latest tags are 20.04 for b/w compat
  docker tag base-docker:20.04 ghcr.io/opensafely-core/base-docker:latest
  docker tag base-action:20.04 ghcr.io/opensafely-core/base-action:latest
  docker push ghcr.io/opensafely-core/base-docker:latest
  docker push ghcr.io/opensafely-core/base-action:latest
