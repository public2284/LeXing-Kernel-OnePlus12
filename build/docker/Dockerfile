# LeXing Kernel build environment.
#
# BASE_IMAGE is pinned to an official Ubuntu LTS release in
# build/docker/toolchain.env; its amd64 manifest digest is recorded by the
# first toolchain-image run (BASE_DIGEST there, plus the built image digest in
# build/docker/image.lock) and verified on every later run.
#
# Security (project rule 13.4.3): the base image is an official Ubuntu
# release, and every toolchain artifact is a shallow git clone from
# googlesource whose resolved HEAD must equal the content-address pin in
# build/docker/checksums.sha256 — the image build aborts on any mismatch.
# No third-party prebuilt binaries from unverified sources.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Build dependencies: pahole (dwarves) is required for CONFIG_DEBUG_INFO_BTF,
# dtc drives the DTB structural checks, python3-yaml backs the in-image static
# checks. Versions are fixed by the pinned base image snapshot; the image
# digest recorded in image.lock is what makes this layer reproducible.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential 
        ca-certificates \
        ccache \
        cpio \
        curl \
        device-tree-compiler \
        dwarves \
        flex \
        git \
        libssl-dev \
        lz4 \
        python3 \
        python3-yaml \
        rsync \
        zip \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# --- Toolchain: AOSP prebuilt clang (r487747c, clang 17.0.2) ------------------
# Shallow clone at the fixed ref; abort unless HEAD equals the pinned commit.
# The prebuilt tree nests its bin one level down (e.g. clang-r487747c/bin), so
# discover it and expose it at a stable path.
ARG CLANG_REPO_URL
ARG CLANG_REF
ARG CLANG_PIN
RUN git clone --depth 1 --branch "${CLANG_REF}" "${CLANG_REPO_URL}" /opt/aosp-clang \
    && test "$(git -C /opt/aosp-clang rev-parse HEAD)" = "${CLANG_PIN}" \
    && rm -rf /opt/aosp-clang/.git \
    && CLANG_BIN_DIR="$(find /opt/aosp-clang -maxdepth 3 -type f -name clang -path '*/bin/*' -printf '%h\n' | head -n1)" \
    && test -n "${CLANG_BIN_DIR}" \
    && ln -sfn "${CLANG_BIN_DIR}" /opt/clang-bin \
    && /opt/clang-bin/clang --version | head -n2
ENV PATH=/opt/clang-bin:$PATH

# --- Host tools: mkbootimg / unpack_bootimg (image structure checks) ----------
ARG MKBOOTIMG_REPO_URL
ARG MKBOOTIMG_REF
ARG MKBOOTIMG_PIN
RUN git clone --depth 1 --branch "${MKBOOTIMG_REF}" "${MKBOOTIMG_REPO_URL}" /opt/mkbootimg \
    && test "$(git -C /opt/mkbootimg rev-parse HEAD)" = "${MKBOOTIMG_PIN}" \
    && rm -rf /opt/mkbootimg/.git \
    && cd /opt/mkbootimg \
    && chmod +x *.py \
    && for f in mkbootimg unpack_bootimg; do [ -e "$f" ] || ln -sf "$f.py" "$f"; done
ENV PATH=/opt/mkbootimg:$PATH

# Sanity: the checks below run on every image build and fail it loudly.
RUN clang --version | head -n1 \
    && ld.lld --version | head -n1 \
    && mkbootimg --help >/dev/null 2>&1 || mkbootimg.py --help >/dev/null 2>&1 \
    && pahole --version \
    && dtc --version | head -n1

WORKDIR /lexing