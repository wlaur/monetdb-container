#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

# shellcheck disable=SC1091
source VERSION

for definition in \
    "ARG MONETDB_RELEASE=${MONETDB_RELEASE}" \
    "ARG MONETDB_VERSION=${MONETDB_VERSION}" \
    "ARG MONETDB_SOURCE_SHA256=${MONETDB_SOURCE_SHA256}" \
    "ARG UBUNTU_VERSION=${UBUNTU_VERSION}" \
    "ARG UBUNTU_DIGEST=${UBUNTU_DIGEST}"; do
    if ! grep --fixed-strings --quiet "$definition" Dockerfile; then
        echo "Dockerfile is not synchronized with VERSION: $definition" >&2
        exit 1
    fi
done

[[ "$MONETDB_SOURCE_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$UBUNTU_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]
[[ "$UPSTREAM_DOCKER_REVISION" =~ ^[0-9a-f]{40}$ ]]
