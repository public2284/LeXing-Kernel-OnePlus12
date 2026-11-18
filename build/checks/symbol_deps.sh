#!/usr/bin/env bash
# L2-static check: symbol dependencies of vendor modules.
#
# For every vendor_dlkm module in the Phase 0 baseline, lists undefined symbols
# and asserts each one is exported by the built kernel. A single missing symbol
# breaks vendor modules at runtime, so this check is strict.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -f "$ROOT/out/Module.symvers" ]] || die "missing out/Module.symvers"
[[ -d "$ROOT/configs/kmi" ]] || die "missing configs/kmi/ (Phase 0 output)"

# Phase 2/3 implementation:
#  - for each baseline module: nm -u (or readelf --dyn-syms via llvm tools) on
#    the module, then require each UND symbol in Module.symvers
#  - report the complete missing-symbol list on failure
die "L2 symbol dependency check is implemented in Phase 3"
