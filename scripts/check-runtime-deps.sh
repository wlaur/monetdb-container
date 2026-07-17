#!/usr/bin/env bash

set -euo pipefail

image="${1:?usage: check-runtime-deps.sh IMAGE}"

docker run --rm --entrypoint bash "$image" -euo pipefail -c '
    paths=(
        /usr/local/bin/mclient
        /usr/local/bin/monetdb
        /usr/local/bin/monetdbd
        /usr/local/bin/mserver5
    )

    while IFS= read -r library; do
        paths+=("$library")
    done < <(find /usr/local/lib -type f \( -name "*.so" -o -name "*.so.*" \) -print)

    missing="$(
        for path in "${paths[@]}"; do
            ldd "$path" 2>&1 || true
        done | sed -n "/not found/p"
    )"

    if [[ -n "$missing" ]]; then
        echo "$missing" >&2
        exit 1
    fi
'
