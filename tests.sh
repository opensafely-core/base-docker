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
        success "$exe was present and executable"
    else
        failure "$exe - could not find $exe"
    fi
}





output=$(mktemp /tmp/output.XXXX)

# test that the entrypoint is invoked properly
test_entrypoint() {
    if ./entrypoint.sh "$@" > "$output" 2>&1; then
        success "entrypoint.sh $*"
    else
        failure "'entrypoint.sh $* exited with $?"
    fi
}

assert_output() {
    local file=$1
    shift
    if grep -q "$@" "$file"; then
        success "'$*' found in $file"
    else
        failure "'$*' not found in $file"
    fi
}


test_executable iostat
test_executable lsof
test_executable netstat
test_executable tcpdump
test_executable vi
test_executable strace


# test install works w/o UPDATE=yes
/root/docker-apt-install.sh make

# test ubuntu pro
if grep -q 'VERSION_ID="20.04"' /etc/os-release; then

  # check we are using packages from ESM archives 
  dpkg-query -W -f='${Package}\t${Version}\n' libssl1.1 > "$output"
  assert_output "$output" "esm"
 
  # check we have not left any files with the token on the image
  if test ! -e /tmp/pro-attach-config.yaml &&
    test ! -d /etc/ubuntu-advantage &&
    test ! -d /var/lib/ubuntu-advantage &&
    test ! -e /var/log/ubuntu-advantage.log &&
    ! dpkg -l | grep -q ubuntu-pro-client; then
    success "no Ubuntu Pro files found"
  else
    failure "Found Ubuntu Pro file that should not be in the image"
  fi
fi

# test script that just echos its arguments for testing
script=$(mktemp /tmp/action_exec.XXXX.sh)
chmod +x "$script"
# Quoting EOF disables expansion. Obvs.
cat > "$script" << 'EOF'
#!/bin/bash
echo "$0" "$@"
EOF


export ACTION_EXEC=$script

# no args
test_entrypoint " "
assert_output "$output" "$script"

# passes args
test_entrypoint a -b --ccc
assert_output "$output" "$script a -b --ccc"

# test default bash ACTION_EXEC works
unset ACTION_EXEC
test_entrypoint "$script" a -b --ccc
assert_output "$output" "$script a -b --ccc"

# check an elf executable is executed directly
test_entrypoint dash -c 'echo SUCCESS'
assert_output "$output" "SUCCESS"

# check we dereference symlinks
# create a symlink to bash in the current dir, so we can use it mounted in /workspace
ln -sf "/usr/bin/bash" "bash.link"
test_entrypoint ./bash.link -c "echo SUCCESS"
assert_output "$output" "SUCCESS"

non_exec_script=$(mktemp /tmp/user_script.XXXX)
echo SUCCESS > "$non_exec_script"

# this should result in 'cat $non_exec_script'
export ACTION_EXEC=cat
test_entrypoint "$non_exec_script"
assert_output "$output" "SUCCESS"

# test windows mounted filesystem behavior: file has execute permission but is not actually executable
chmod +x "$non_exec_script"
test_entrypoint "$non_exec_script"
assert_output "$output" "SUCCESS"

exit $failed
