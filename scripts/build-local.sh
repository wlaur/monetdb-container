#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

# shellcheck disable=SC1091
source VERSION

image="${1:-monetdb-container:test}"

docker buildx build \
    --platform linux/arm64 \
    --load \
    --tag "$image" \
    --build-arg "MONETDB_RELEASE=${MONETDB_RELEASE}" \
    --build-arg "MONETDB_VERSION=${MONETDB_VERSION}" \
    --build-arg "MONETDB_SOURCE_SHA256=${MONETDB_SOURCE_SHA256}" \
    --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}" \
    --build-arg "UBUNTU_DIGEST=${UBUNTU_DIGEST}" \
    .
