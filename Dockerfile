FROM ubuntu:noble AS osxcross-builder

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
        curl \
        unzip \
        patch \
        coreutils \
        python3 \
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

ARG WORKDIR=/build
ARG OSX_CROSS_PATH=/usr/local/osxcross
ARG OSX_CROSS_COMMIT
ARG OSX_SDK
ARG OSX_SDK_SUM
ARG OSX_VERSION_MIN

WORKDIR "$WORKDIR"

COPY patches /patches

RUN \
    git clone https://github.com/tpoechtrager/osxcross.git . \
 && git config user.name "John Doe" \
 && git config user.email johndoe@example.com \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git

#&& git am < /patches/libcxx.patch
#COPY ./ $WORKDIR/

#RUN
#    cd osxcross
# && git config user.name "John Doe"
# && git config user.email johndoe@example.com
# && git am < ../patches/libcxx.patch

COPY tars/${OSX_SDK}.tar.xz "$WORKDIR/tarballs/${OSX_SDK}.tar.xz"

RUN \
    echo "${OSX_SDK_SUM}" "tarballs/${OSX_SDK}.tar.xz" | sha256sum -c - \
 && UNATTENDED=1 TARGET_DIR="$OSX_CROSS_PATH" OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM debian:trixie-slim

ARG OSX_CROSS_PATH=/usr/local/osxcross

LABEL maintainer="Artur Troian <troian dot ap at gmail dot com>"
LABEL "org.opencontainers.image.source"="https://github.com/goreleaser/goreleaser-osxcross"

COPY --from=osxcross-builder "${OSX_CROSS_PATH}" "${OSX_CROSS_PATH}"

ENV PATH=$PATH:"$OSX_CROSS_PATH/bin"
