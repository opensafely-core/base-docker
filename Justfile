import 'justfile.base'

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

@lint-docker:
    {{ docker_run_safe }} -i ghcr.io/hadolint/hadolint:{{ hadolint_version }} < Dockerfile

@shellcheck:
    {{ docker_run_safe }} -v "$PWD:/mnt:ro" koalaman/shellcheck:{{ shellcheck_version }} *.sh

@lint-actions:
    {{ docker_run_safe }} -v $(pwd):/repo:ro --workdir /repo kjanat/actionlint:{{ actionlint_version }} -color

lint:
    -just lint-docker
    -just shellcheck
    -just lint-actions

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

    docker compose run $RUN_ARGS --rm -v {{ justfile_directory() }}:/tests -w /tests "$ACTION_IMAGE_NAME-20.04" ./tests.sh
    docker compose run $RUN_ARGS --rm -v {{ justfile_directory() }}:/tests -w /tests "$ACTION_IMAGE_NAME-22.04" ./tests.sh
    docker compose run $RUN_ARGS --rm -v {{ justfile_directory() }}:/tests -w /tests "$ACTION_IMAGE_NAME-24.04" ./tests.sh
    ./check.sh

# Update the files tracking the digests of ubuntu docker image
update-docker-image-digests:
    @just _update-image-digest "ubuntu" "20.04"
    @just _update-image-digest "ubuntu" "22.04"

_update-image-digest os version:
    #!/bin/bash
    set -euo pipefail
    image_name={{ os }}:{{ version }}
    echo "$image_name"
    docker image pull "$image_name"
    # Find the full qualified "repo digest" for this image
    image_digest=$(docker inspect --format='{{{{join .RepoDigests "\n"}}' "$image_name" | grep -F '{{ os }}')
    echo "$image_digest" > "$image_name.digest"

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


check-renovate-config:
    {{ docker_run_safe }} -v $(pwd):/repo:ro --workdir /repo renovate/renovate:{{ renovate_version }} renovate-config-validator

# Show what updates Renovate would propose.
# summary: table with version age and pending status
# packages: structured JSON of proposed package updates

# full: complete Renovate debug log
renovate-dry-run output="summary":
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Running Renovate, this may take a few minutes" >&2

    # Buffer Renovate's output so progress dots can't appear in the middle of the formatted JSON or summary table.
    log_file=$(mktemp)
    progress_pid=""

    cleanup() {
        if [[ -n "$progress_pid" ]]; then
            kill "$progress_pid" 2>/dev/null || true
            wait "$progress_pid" 2>/dev/null || true
            progress_pid=""
        fi
        rm -f "$log_file"
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    run_renovate() {
        # We can't use docker_run_safe because --network none prevents
        # Renovate querying Docker, GitHub, PyPI, etc.
        #
        # Renovate also needs writable working/cache directories.
        # Give it a tmpfs mount and leave everything else read-only.

        # Let the user know something is still happening.
        (
            while sleep 5; do
                printf '.' >&2
            done
        ) &
        progress_pid=$!

        local status=0

        docker run --rm --read-only --tmpfs /tmp \
            --cap-drop ALL \
            --security-opt no-new-privileges:true \
            --user 65534:65534 \
            -e HOME=/tmp \
            -v "$(pwd):/repo:ro" \
            --workdir /repo \
            -e LOG_LEVEL=debug \
            -e LOG_FORMAT=json \
            renovate/renovate:{{ renovate_version }} \
            --platform=local > "$log_file" || status=$?

        # Stop the progress indicator before printing any output.
        kill "$progress_pid" 2>/dev/null || true
        wait "$progress_pid" 2>/dev/null || true
        progress_pid=""
        echo >&2

        return "$status"
    }

    # Run Renovate once, then format the buffered output.
    if ! run_renovate; then
        echo "Renovate failed. Last 30 log lines:" >&2
        tail -n 30 "$log_file" >&2
        exit 1
    fi

    case "{{ output }}" in
         summary)
            jq -rRn '
                # Truncate digests to the first 19 characters.
                # Keep the full version number.
                def format_digest:
                    if . then
                        "@" + .[:19] + "..."
                    else
                        ""
                    end;

                # Only display digests for Docker and GitHub Actions.
                def display_digest($manager):
                    if ($manager == "docker" or $manager == "github-actions") then
                        format_digest
                    else
                        ""
                    end;

                [
                    "PACKAGE",
                    "CURRENT VERSION",
                    "CURRENT VALUE",
                    "NEW VERSION",
                    "NEW VALUE",
                    "AGE",
                    "STATUS"
                ],
                (
                    inputs
                    | fromjson?
                    | objects
                    | select(.msg == "packageFiles with updates")
                    | .config[][]
                    | .manager as $manager
                    | .deps[]
                    | . as $dep
                    | $dep.depName as $name
                    | ($dep.lockedVersion // $dep.currentVersion // "-") as $currentVersion
                    | ($dep.currentValue // "-") as $currentValue
                    | ($dep.updates // [])[]
                    | [
                        $name,
                        ($currentVersion + ($dep.currentDigest | display_digest($manager))),
                        $currentValue,
                        (
                        (.newVersion // "-")
                        + (.newDigest | display_digest($manager))
                        ),
                        (.newValue // "-"),
                        (
                        if .newVersionAgeInDays != null then
                            "\(.newVersionAgeInDays)d"
                        else
                            "-"
                        end
                        ),
                        (if .pendingChecks then "pending" else "ready" end)
                    ]
                )
                | @tsv
            ' "$log_file" | column -t -s $'\t'
            ;;

        packages)
            jq -R '
                fromjson?
                | objects
                | select(.msg == "packageFiles with updates")
                | .config
            ' "$log_file"
            ;;

        full)
            jq -R 'fromjson? // .' "$log_file"
            ;;

        *)
            echo "Unknown output '{{ output }}': use 'summary', 'packages' or 'full'" >&2
            exit 1
            ;;
    esac

# Run a full Renovate dry run against this branch (requires pushing the branch first)
renovate-dry-run-github branch:
    # This checks some things that renovate-dry-run (which runs against local files)
    # can't, e.g. lockFileMaintenance, which depend on it determinining what branches
    # and PRs it would need to make.
    # Note that we can't use docker_run_safe here because `--network none` stops
    # Renovate querying docker, github, pypi etc for updates. It's not --read-only
    # because it needs to install uv and npm; however, it doesn't need to mount in
    # any local files because it's pulling a remote branch.
    docker run --rm --tmpfs /tmp \
        --cap-drop ALL --security-opt no-new-privileges:true \
        -e LOG_LEVEL=debug -e LOG_FORMAT=json \
        -e RENOVATE_TOKEN="$(gh auth token)" \
        renovate/renovate:{{ renovate_version }} \
        --platform=github --dry-run=full \
        --base-branch-patterns={{ branch }} --use-base-branch-config=merge \
        opensafely-core/base-docker
