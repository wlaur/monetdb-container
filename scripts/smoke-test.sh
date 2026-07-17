#!/usr/bin/env bash

set -euo pipefail

image="${1:?usage: smoke-test.sh IMAGE}"
suffix="${GITHUB_RUN_ID:-local}-$$"
container="monetdb-smoke-${suffix}"
volume="monetdb-smoke-${suffix}"

cleanup() {
    docker rm --force "$container" >/dev/null 2>&1 || true
    docker volume rm "$volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT

platform="$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")"
if [[ "$platform" != "linux/arm64" ]]; then
    echo "expected linux/arm64 image, got $platform" >&2
    exit 1
fi

user="$(docker image inspect --format '{{.Config.User}}' "$image")"
if [[ "$user" != "monetdb" ]]; then
    echo "expected image user monetdb, got $user" >&2
    exit 1
fi

setid_files="$(
    docker run --rm --entrypoint find "$image" /usr/bin /usr/sbin \
        -xdev -type f \( -perm -4000 -o -perm -2000 \) -print
)"
if [[ -n "$setid_files" ]]; then
    echo "unexpected setuid/setgid files:" >&2
    echo "$setid_files" >&2
    exit 1
fi

docker volume create "$volume" >/dev/null

start_container() {
    docker run --detach \
        --name "$container" \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=64m \
        --mount "type=volume,source=$volume,target=/var/monetdb5/dbfarm" \
        --publish 127.0.0.1::50000 \
        --env MDB_DB_ADMIN_PASS=monetdb \
        --env MDB_CREATE_DBS=test \
        "$image" >/dev/null
    docker exec "$container" bash -c \
        'umask 077; printf "user=monetdb\npassword=monetdb\n" > /tmp/smoke.monetdb'
}

query() {
    docker exec --interactive --env DOTMONETDBFILE=/tmp/smoke.monetdb "$container" \
        mclient --host=127.0.0.1 --port=50000 \
        --database=test --format=raw
}

wait_until_ready() {
    for _ in {1..90}; do
        if printf 'SELECT 1;\n' | query >/dev/null 2>&1; then
            return
        fi
        if [[ "$(docker inspect --format '{{.State.Running}}' "$container")" != "true" ]]; then
            docker logs "$container" >&2
            return 1
        fi
        sleep 1
    done
    docker logs "$container" >&2
    echo "MonetDB did not become ready" >&2
    return 1
}

start_container
wait_until_ready

published_port="$(docker port "$container" 50000/tcp)"
[[ "$published_port" == 127.0.0.1:* ]]

result="$(
    query <<'SQL'
SELECT value FROM sys.environment WHERE name = 'monet_version';
SELECT value FROM sys.environment WHERE name = 'monet_release';
SELECT 1;
SELECT CAST(ST_Point(1, 2) AS VARCHAR(100));
CREATE TABLE "Smoke Table" ("Text Value" VARCHAR(32));
INSERT INTO "Smoke Table" VALUES ('ÅÄÖ');
SELECT "Text Value" FROM "Smoke Table";
SQL
)"
grep --fixed-strings --quiet "11.55.7" <<< "$result"
grep --fixed-strings --quiet "Dec2025-SP3" <<< "$result"
grep --fixed-strings --quiet "1" <<< "$result"
grep --fixed-strings --quiet "POINT (1 2)" <<< "$result"
grep --fixed-strings --quiet "ÅÄÖ" <<< "$result"

docker stop --time 30 "$container" >/dev/null
exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$container")"
if [[ "$exit_code" != "0" ]]; then
    docker logs "$container" >&2
    echo "container exited with status $exit_code" >&2
    exit 1
fi
docker rm "$container" >/dev/null

start_container
wait_until_ready

persisted="$(printf 'SELECT "Text Value" FROM "Smoke Table";\n' | query)"
grep --fixed-strings --quiet "ÅÄÖ" <<< "$persisted"

if docker logs "$container" 2>&1 | grep --fixed-strings --quiet "Creating database 'test'"; then
    echo "persistent restart unexpectedly repeated database initialization" >&2
    exit 1
fi

echo "Smoke test passed for $image ($platform)"
