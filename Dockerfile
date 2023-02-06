FROM debian:bullseye AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR

# Install deps
SHELL ["/bin/bash", "-c"]
RUN \
    set -x; \
    echo "Starting image build for Debian" \
 && apt-get update \
 && apt-get install --no-install-recommends -y -q \
        make \
        build-essential \
        clang \
        gcc \
        g++ \
        git \
        cmake \
        coreutils \
        ca-certificates \
        autotools-dev \
        libxml2-dev \
        lzma-dev \
        libssl-dev \
        zlib1g-dev \
        libmpc-dev \
        libmpfr-dev \
        libgmp-dev \
        llvm-dev \
        uuid-dev \
 && apt -y autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
 && rm -rf /usr/share/man/* \
    /usr/share/doc

ENV OSX_CROSS_PATH=/osxcross

ARG OSX_CROSS_COMMIT
ARG OSX_SDK
ARG OSX_SDK_SUM
ARG OSX_VERSION_MIN

WORKDIR "${OSX_CROSS_PATH}"

COPY patches /patches

RUN \
    git clone https://github.com/tpoechtrager/osxcross.git . \
 && git config user.name "John Doe" \
 && git config user.email johndoe@example.com \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && git am < /patches/libcxx.patch \
 && rm -rf ./.git

# install osxcross:
COPY tars/${OSX_SDK}.tar.xz "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"

RUN \
    echo "${OSX_SDK_SUM}" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c - \
 && UNATTENDED=1 OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM debian:bullseye-slim AS final

LABEL maintainer="Artur Troian <troian dot ap at gmail dot com>"
LABEL "org.opencontainers.image.source"="https://github.com/goreleaser/goreleaser-osxcross"

COPY --from=builder "${OSX_CROSS_PATH}/target" "${OSX_CROSS_PATH}/target"
