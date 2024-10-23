#!/bin/bash
set -euo pipefail

failed=0
for version in 20.04 22.04 24.04
do 
    for image_name in base-docker base-action
    do
        image="$image_name:$version"
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
done

exit $failed
