#!/usr/bin/env bash
# L2-static check: compiled configuration.
#
# Diffs the merged defconfig against the final out/.config with the kernel's
# scripts/diffconfig, and fails if any symbol on the protection list (security
# and boot-critical CONFIGs) was silently changed.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -f "$ROOT/out/.config" ]] || die "missing out/.config"
[[ -f "$ROOT/kernel/scripts/diffconfig" ]] || die "kernel source not present"

# Phase 2/3 implementation:
#  - python3 kernel/scripts/diffconfig <profile-merged-config> out/.config
#  - fail on changes touching the protection list (documented in configs/)
#  - attach the full diff to the test report
die "L2 kconfig diff check is implemented in Phase 3"
