# LeXing Kernel build environment.
#
# Status: specification only. BASE_IMAGE is empty on purpose — it is chosen
# during Phase 1/2 (after the kernel branch and toolchain requirements are
# known) and pinned by digest in build/docker/image.lock. Building this file
# with an empty BASE_IMAGE fails loudly, which is intended.
#
# Security (project rule 13.4.3): the base image is an official Ubuntu release,
# and every toolchain artifact fetched during the image build is verified
# against build/docker/checksums.sha256. No third-party prebuilt binaries from
# unverified sources.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Build dependencies. Versions are fixed by the pinned base image snapshot; the
# image digest in image.lock is what makes this layer reproducible.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential \
        ccache \
        cpio \
        curl \
        flex \
        git \
        libssl-dev \
        lz4 \
        python3 \
        rsync \
        zip \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# Toolchain fetching (Phase 2): download the pinned AOSP prebuilt clang and host
# tools, verify each against checksums.sha256, and fail the image build on any
# checksum mismatch. Implemented in Phase 2 together with the pins in
# toolchain.env.

WORKDIR /lexing
