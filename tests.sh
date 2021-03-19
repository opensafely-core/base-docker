#!/bin/bash
# Note: idealy, we'd use python, but the base-docker image does not have it
# installed!
set -euo pipefail

failed=0

success() {
    echo "OK: $*"
}

failure() {
    echo "FAIL: $*"
    failed=1
}

# test string is an executable on the path
test_executable() {
    local exe=$1
    if command -v "$exe" > /dev/null; then
        success "$exe"
    else
        failure "$exe - could not find $exe"
    fi
}


# test script that just echos its arguments.
script=$(mktemp)
chmod +x "$script"
# Quoting EOF disables expansion. Obvs.
cat > "$script" << 'EOF'
#!/bin/bash
echo "$0" "$@"
EOF


# test that the entrypoint is invoked properly
test_entrypoint() {
    local exe output expected
    output=$(/root/entrypoint.sh "$@")
    if test -n "${ACTION_EXEC:-}"; then
        expected="${script} $*"
    else
        expected="$*"
    fi
    if test "${output}" = "$expected"; then
        success "entrypoint.sh $*"
    else
        failure "'entrypoint.sh $*' did not return correct output"
        echo "output='$output'"
        echo "expected='$expected'"
    fi
}

test_executable iostat
test_executable lsof
test_executable netstat
test_executable tcpdump
test_executable vim
test_executable strace


export ACTION_EXEC=$script
test_entrypoint " "
test_entrypoint a -b --ccc
unset ACTION_EXEC
test_entrypoint "$script" a -b --ccc

exit $failed

