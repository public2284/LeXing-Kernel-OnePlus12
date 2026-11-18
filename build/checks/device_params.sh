#!/usr/bin/env bash
# L2-static check: device parameters.
#
# Compares the built kernel's release string, boot parameters and header
# metadata against the Phase 0 device baseline in configs/device/. Static
# comparison — passing it never implies the kernel boots.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -f "$ROOT/out/build-info.json" ]] || die "missing out/build-info.json"
[[ -d "$ROOT/configs/device" ]] || die "missing configs/device/ (Phase 0 output)"

# Phase 2/3 implementation:
#  - kernel release string from out/build-info.json matches the device's
#    /proc/version baseline
#  - boot cmdline subset (from Phase 0 dump) is preserved
#  - boot image header version matches the device's original image
die "L2 device parameter check is implemented in Phase 3 against the Phase 0 device baseline"
