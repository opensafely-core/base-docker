#!/bin/bash
set -euo pipefail

executable=${ACTION_EXEC:-bash}

if test -n "${1:-}"; then
    if command -v -- "$1" >/dev/null 2>&1; then
        # special case - the user has provided their own valid executable as
        # the first argument, so switch to executing that
        executable=$1
        shift
    fi
fi

exec "$executable" "$@"
