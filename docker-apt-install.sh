#!/bin/bash
# Useful utility to install system packages from a file
# It does so in the lowest footprint way possible, in a single RUN command.
set -euo pipefail

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

# clean up if we've upgraded
if test "${UPGRADE:-}" = "yes"; then
    apt-get autoremove --yes 
fi
