#!/bin/bash
# Useful utility to install system packages from a file
# It does so in the lowest footprint way possible, by removing apt lists afterwards
set -euo pipefail

# ensure apt lists are populated
apt-get update

# do we want to upgrade too?
test "${UPGRADE:-}" = "yes" && apt-get upgrade --yes

PACKAGES=
for arg in "$@"; do
    if test -f $arg; then
        # argument is a file
        # strip any comments and install every package listed in the file
        sed 's/^#.*//' "$arg" | xargs apt-get install --yes --no-install-recommends
    else
        # argument is a package name, add to install list
        PACKAGES="$PACKAGES $arg"
    fi
done

test -n "$PACKAGES" && apt-get install --yes --no-install-recommends $PACKAGES

# clean up if we've upgraded
test "${UPGRADE:-}" = "yes" && apt-get autoremove --yes

# We do not apt-get clean becuase the default debian docker apt config does that for us.
# Doing this saves us ~50MB, but means we need to apt-get update before we can install anything again
rm -rf /var/lib/apt/lists/*
