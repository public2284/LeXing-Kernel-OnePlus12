#!/usr/bin/env bash
# L1-format check: boot image structure.
#
# Packs a verification boot.img with the pinned mkbootimg and unpacks it again
# with unpack_bootimg, asserting header version, section sizes and alignment.
# This validates the packaging toolchain and image structure ONLY: it says
# nothing about whether the kernel boots on the actual device.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -f "$ROOT/out/Image" ]] || die "missing out/Image"
command -v mkbootimg >/dev/null 2>&1 || die "mkbootimg not in PATH (needs the pinned builder image)"
command -v unpack_bootimg >/dev/null 2>&1 || die "unpack_bootimg not in PATH (needs the pinned builder image)"

# Phase 2/3 implementation: build the verification image with the header
# parameters captured in Phase 0 (kernel offset, page size, header version),
# unpack it, and compare the round trip field by field.
die "L1 image structure check is implemented in Phase 3 together with the pinned mkbootimg"
