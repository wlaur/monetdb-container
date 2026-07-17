# syntax=docker/dockerfile:1.20@sha256:26147acbda4f14c5add9946e2fd2ed543fc402884fd75146bd342a7f6271dc1d

ARG UBUNTU_VERSION=24.04
ARG UBUNTU_DIGEST=sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90

FROM ubuntu:${UBUNTU_VERSION}@${UBUNTU_DIGEST} AS build

ARG MONETDB_RELEASE=Dec2025-SP3
ARG MONETDB_VERSION=11.55.7
ARG MONETDB_SOURCE_SHA256=533042923b6a19d51a4ed5a31fe3e7d9c8bc156ba1f88f9a5fe9305059cacdfd
ARG BUILD_THREADS=4
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        libbz2-dev \
        liblz4-dev \
        liblzma-dev \
        libpcre2-dev \
        libssl-dev \
        pkg-config \
        python3 \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/monetdb
RUN curl --fail --location --proto '=https' --tlsv1.2 \
        --output MonetDB.tar.bz2 \
        "https://www.monetdb.org/downloads/sources/${MONETDB_RELEASE}/MonetDB-${MONETDB_VERSION}.tar.bz2" \
    && echo "${MONETDB_SOURCE_SHA256}  MonetDB.tar.bz2" | sha256sum --check - \
    && mkdir source \
    && tar --extract --bzip2 --file MonetDB.tar.bz2 \
        --directory source --strip-components=1

WORKDIR /tmp/monetdb/source/build
RUN cmake .. \
        -DASSERT=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DINT128=ON \
        -DPY3INTEGRATION=OFF \
        -DRELEASE_VERSION=ON \
        -DRINTEGRATION=OFF \
        -DSTRICT=OFF \
        -DWITH_OPENSSL=ON \
    && cmake --build . --parallel "${BUILD_THREADS}" \
    && cmake --install .

FROM ubuntu:${UBUNTU_VERSION}@${UBUNTU_DIGEST} AS runtime

ARG MONETDB_RELEASE=Dec2025-SP3
ARG MONETDB_VERSION=11.55.7
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bash \
        ca-certificates \
        libbz2-1.0 \
        liblz4-1 \
        liblzma5 \
        libpcre2-8-0 \
        libssl3t64 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/ /usr/local/
COPY --chmod=0755 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY LICENSE /licenses/MPL-2.0.txt

RUN groupadd --gid 5000 monetdb \
    && useradd --uid 5000 --gid 5000 --create-home monetdb \
    && mkdir --parents /var/monetdb5/dbfarm \
    && chown --recursive monetdb:monetdb /var/monetdb5 \
    && find /usr/bin /usr/sbin -xdev -type f -perm /6000 -exec chmod a-s {} +

LABEL org.opencontainers.image.title="Unofficial MonetDB container" \
      org.opencontainers.image.description="Native Linux ARM64 build of MonetDB" \
      org.opencontainers.image.documentation="https://github.com/wlaur/monetdb-container#readme" \
      org.opencontainers.image.source="https://github.com/wlaur/monetdb-container" \
      org.opencontainers.image.licenses="MPL-2.0" \
      org.opencontainers.image.version="${MONETDB_VERSION}" \
      org.opencontainers.image.vendor="wlaur (unofficial build)" \
      org.monetdb.release="${MONETDB_RELEASE}"

VOLUME ["/var/monetdb5/dbfarm"]
EXPOSE 50000
USER monetdb
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
