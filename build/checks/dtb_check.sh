#!/usr/bin/env bash
# L3-static check: DTB/DTBO compatibility.
#
# Compares the built devicetree blobs against the device's extracted originals
# with dtc: new or removed nodes (display, touch, UFS, power, etc.) must be
# zero or explicitly acknowledged. Structural comparison only — a identical
# DTB still does not prove the kernel brings the hardware up.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -d "$ROOT/out/dtb" ]] || die "missing out/dtb"
[[ -d "$ROOT/configs/device/dtb" ]] || die "missing configs/device/dtb/ (Phase 0 extracted baseline)"

# Phase 2/3 implementation:
#  - dtc -I dtb -O dts decompile both sides, diff -u, filter noise
#  - fail on any added/removed node outside an approved allowlist
#  - attach the diff to the test report
die "L3 DTB/DTBO check is implemented in Phase 3 against the Phase 0 baseline"
