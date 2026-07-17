# MonetDB container

Unofficial container images for [MonetDB](https://www.monetdb.org/), initially
targeting native `linux/arm64`.

The current image contains MonetDB Dec2025-SP3 (11.55.7). MonetDB's official
Docker Hub image currently supplies `linux/amd64`; this repository fills the
native ARM64 gap for Apple Silicon development environments and ARM CI
runners. It is not an official MonetDB distribution.

## Images

Release tags publish to:

```text
ghcr.io/wlaur/monetdb-container:11.55.7
ghcr.io/wlaur/monetdb-container:Dec2025-SP3
```

Both aliases point to the same `linux/arm64` image. A revisioned immutable tag,
such as `11.55.7-1`, is also published. There is intentionally no `latest` tag.
Docker Hub receives the same tags when the repository's optional
[Docker Hub settings](DOCKER_HUB.md) are configured.

Docker containers use a Linux kernel. On an Apple Silicon Mac, OrbStack or
Docker Desktop runs this `linux/arm64` image natively inside its Linux VM. A
native macOS package would be a separate artifact, not a Docker image.

## Run

Create a database named `test`, expose MAPI on local port 50000, and persist the
database farm:

```console
docker volume create monetdb-data
docker run --detach \
  --name monetdb \
  --publish 50000:50000 \
  --mount type=volume,source=monetdb-data,target=/var/monetdb5/dbfarm \
  --env MDB_DB_ADMIN_PASS=monetdb \
  --env MDB_CREATE_DBS=test \
  ghcr.io/wlaur/monetdb-container:11.55.7
```

Do not use the example password outside local development.

The entrypoint follows MonetDB's official container behavior and recognizes:

- `MDB_CREATE_DBS`: comma-separated database names; defaults to `monetdb`
- `MDB_DB_ADMIN_PASS` or `MDB_DB_ADMIN_PASS_FILE`
- `MDB_DAEMON_PASS` or `MDB_DAEMON_PASS_FILE`
- `MDB_FARM_DIR`, `MDB_LOGFILE`, and `MDB_SNAPSHOT_DIR`
- `MDB_SNAPSHOT_COMPRESSION`
- `MDB_FARM_PROPERTIES` and `MDB_DB_PROPERTIES`
- `MDB_SHOW_VARS`

Initialization runs only once per database-farm volume. The process runs as
UID/GID 5000 and MonetDB receives `SIGINT` directly when the container stops.

## Build and test locally

An ARM64 Docker engine is the fastest option. Apple Silicon with OrbStack works
without emulation:

```console
scripts/check-version.sh
scripts/build-local.sh
scripts/check-runtime-deps.sh monetdb-container:test
scripts/smoke-test.sh monetdb-container:test
```

The smoke test verifies the image platform, authenticated startup, the exact
MonetDB version, SQL and Unicode round trips, quoted identifiers, clean
shutdown, read-only-root operation, and persistent restart behavior.

## Pinned inputs

[`VERSION`](VERSION) records every reviewed release input:

- MonetDB Dec2025-SP3 source archive, version 11.55.7
- SHA-256 `533042923b6a19d51a4ed5a31fe3e7d9c8bc156ba1f88f9a5fe9305059cacdfd`
- Ubuntu 24.04 multi-platform base-image digest
- upstream container revision used for the entrypoint

The source checksum matches MonetDB's
[PGP-signed checksum file](https://www.monetdb.org/downloads/sources/Dec2025-SP3/SHA256SUM).
The build verifies the archive checksum before extraction. GitHub Actions are
pinned by full commit SHA, release images include OCI provenance and an SBOM,
and Trivy scans both builds and the published image.

## Releases

The native ARM64 build and smoke test run on every pull request and push. A tag
matching `v<MonetDB-version>-<image-revision>`, for example `v11.55.7-1`,
publishes the image:

```console
git tag v11.55.7-1
git push origin v11.55.7-1
```

Before tagging, confirm the main-branch build is green. Record the resulting
digest in the GitHub release and consume that digest from downstream CI.

Additional Linux architectures can later be added as native build jobs and
combined into one multi-platform manifest without changing the repository or
image name.

## Upstream and license

The Dockerfile follows MonetDB's MPL-2.0
[container repository](https://github.com/MonetDBSolutions/monetdb-docker) at
revision
[`41b59b065f62f852647920001f6f6953287e4169`](https://github.com/MonetDBSolutions/monetdb-docker/commit/41b59b065f62f852647920001f6f6953287e4169).
The adapted entrypoint preserves its source header and attribution.

This repository is licensed under the [Mozilla Public License 2.0](LICENSE).
MonetDB source and its own notices are available from the
[official release archive](https://www.monetdb.org/downloads/sources/Dec2025-SP3/).
