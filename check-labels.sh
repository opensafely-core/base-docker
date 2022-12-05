#!/bin/bash
set -euo pipefail

failed=0
for image in base-docker:20.04 base-docker:22.04 base-action:20.04
do
    for label in build-date vcs-ref
    do
        full="org.opensafely.base.$label"
        value="$(docker inspect -f "{{ index .Config.Labels \"$full\" }}" "$image")"

        echo "$image: $full=$value"
        test -n "$value" || { failed=1; echo "Empty $full label"; }
    done
done

exit $failed
