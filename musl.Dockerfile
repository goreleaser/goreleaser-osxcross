FROM alpine:3.22 AS builder

RUN \
    apk add --no-cache \
        bash \
        clang \
        clang-dev \
        gcc \
        g++ \
        git \
        libxml2-dev \
        fts-dev \
        gmp-dev \
        mpfr-dev \
        mpc1-dev \
        libuuid \
        make \
        musl-dev \
        openssl-dev \
        patch \
        python3 \
        coreutils \
        perl \
        bsd-compat-headers \
        cmake \
        curl \
        unzip

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

COPY tars/${OSX_SDK}.tar.xz "$WORKDIR/tarballs/${OSX_SDK}.tar.xz"

RUN \
    echo "${OSX_SDK_SUM}" "tarballs/${OSX_SDK}.tar.xz" | sha256sum -c - \
 && UNATTENDED=1 TARGET_DIR="$OSX_CROSS_PATH" OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM alpine:3.22

ARG OSX_CROSS_PATH=/usr/local/osxcross

LABEL maintainer="Artur Troian <troian dot ap at gmail dot com>"
LABEL "org.opencontainers.image.source"="https://github.com/goreleaser/goreleaser-osxcross"

COPY --from=builder "${OSX_CROSS_PATH}" "${OSX_CROSS_PATH}"

ENV PATH=$PATH:"$OSX_CROSS_PATH/bin"
