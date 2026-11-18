#!/usr/bin/env bash
# L2-static check: KMI (Kernel Module Interface) stability.
#
# Two directions, both required:
#  - the kernel's own ABI tooling (build/build_abi.sh on ACK, or the fallback
#    Module.symvers comparison) reports no breaking change versus
#    abi_gki_aarch64.xml in the source tree
#  - every symbol the device's vendor modules need (Phase 0 baseline in
#    configs/kmi/) is still exported
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -f "$ROOT/out/Module.symvers" ]] || die "missing out/Module.symvers"
[[ -d "$ROOT/configs/kmi" ]] || die "missing configs/kmi/ (Phase 0 output)"

# Phase 2/3 implementation:
#  - run the ACK ABI tooling over the build output, or compare generated symbol
#    lists against the tree's abi_gki_aarch64.xml
#  - resolve every required symbol from configs/kmi/ against Module.symvers
die "L2 KMI check is implemented in Phase 3 together with the kernel ABI tooling"
