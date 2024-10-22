#!/bin/bash
set -euo pipefail

failed=0
for image in base-docker:20.04 base-docker:22.04 base-action:20.04
do
    tag=$(echo $image | awk -F: '{print $NF}')
    os_version=$(docker run $image grep VERSION_ID= /etc/os-release)
    echo "$image: OS $os_version"
    test "$os_version" = "VERSION_ID=\"${tag}\"" || { failed=1; echo "Expected os version to be $tag"; }

    for label in created gitref
    do
        full="org.opensafely.base.$label"
        value="$(docker inspect -f "{{ index .Config.Labels \"$full\" }}" "$image")"

        echo "$image: $full=$value"
        test -n "$value" || { failed=1; echo "Empty $full label"; }
    done
done

exit $failed
