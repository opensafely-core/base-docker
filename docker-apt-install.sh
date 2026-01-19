#!/bin/bash
# Useful utility to install system packages from a file
# It does so in the lowest footprint way possible, in a single RUN command.
set -euo pipefail
set -x

pro_attached=0
pro_token_file=/run/secrets/ubuntu_pro_token


if grep -q 'VERSION_ID="20.04"' /etc/os-release; then
    # enable ubuntu pro, based on the example in the Canonical docs:
    # https://documentation.ubuntu.com/pro-client/en/docs/howtoguides/enable_in_dockerfile/
    # A file is used rather than an env var which would leak into the docker metadata.
    #
    # We do it in this helper script, rather than in the Dockerfile, so that
    # downstream docker images can also re-use this logic and enable esm
    # installations.
    #
    # We enable two additional archives:
    #  - esm-infra: core infra packages
    #  - esm-apps: applications and server packages
    if test -s "$pro_token_file"; then
        apt-get update
        apt-get install --no-install-recommends -y ubuntu-pro-client ca-certificates
        cat > /tmp/pro-attach-config.yaml <<EOF
token: $(cat "$pro_token_file")
enable_services:
  - esm-infra
  - esm-apps
EOF
        pro attach --attach-config /tmp/pro-attach-config.yaml
        rm -f /tmp/pro-attach-config.yaml
        pro_attached=1
    fi
fi

# ensure apt lists are populated
apt-get update

# do we want to upgrade too?
test "${UPGRADE:-}" = "yes" && apt-get upgrade --yes

PACKAGES=
for arg in "$@"; do
    if test -f "$arg"; then
        # argument is a file
        # strip any comments and install every package listed in the file
        sed 's/^#.*//' "$arg" | xargs apt-get install --yes --no-install-recommends
    else
        # argument is a package name, add to install list
        PACKAGES="$PACKAGES $arg"
    fi
done

if test -n "$PACKAGES"; then
    # shellcheck disable=SC2086
    apt-get install --yes --no-install-recommends $PACKAGES
fi

if test "$pro_attached" = "1"; then
    # remove the ubuntu pro, so it will not persist in the final layer
    pro detach --assume-yes
    apt-get purge --auto-remove -y ubuntu-pro-client
fi

# clean up if we've upgraded
if test "${UPGRADE:-}" = "yes"; then
    apt-get autoremove --yes 
fi
