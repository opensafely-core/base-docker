#!/bin/bash
set -euo pipefail

script_executable=${ACTION_EXEC:-bash}
interactive_executable=${INTERACTIVE_EXEC:-$script_executable}

is_real_executable() {
    local path shebang 
    path="$(which "$1")"

    # check for shebang
    IFS= LC_ALL=C read -rn2 -d '' shebang < "$path"
    if test "$shebang" = "#!"; then
        return 0
    fi

    # check for binfmt
    if file -L "$path" | grep -q ELF; then
        return 0
    fi

    return 1

}

if test -n "${1:-}"; then
    # we have arguments, so default to executing a file
    executable=$script_executable

    # However, check if the first argument is a valid executable, and use that instead.
    # This allows a pattern of `docker run image exec` to run whatever excuteable you want.
    if command -v -- "$1" >/dev/null 2>&1; then
        # on windows, all files have executable mask, so check it is actually executable
        if is_real_executable "$1"; then
            # special case - the user has provided their own valid executable as
            # the first argument, so switch to executing that
            executable=$1
            shift
        fi
    fi

else
    # no arguments - we want the interactive executable
    executable=$interactive_executable
fi

exec "$executable" "$@"
