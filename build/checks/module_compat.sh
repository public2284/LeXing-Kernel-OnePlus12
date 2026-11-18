#!/usr/bin/env bash
# L2-static check: module compatibility.
#
# Asserts every built module's vermagic matches the built kernel release and
# every 'depends' entry resolves to a module actually present. modpost warnings
# count as failures (a clean build is part of the definition of done).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

[[ -d "$ROOT/out/modules" ]] || die "missing out/modules"
[[ -n "$(find "$ROOT/out/modules" -name '*.ko' | head -n1)" ]] || die "no built .ko files to verify"

# Phase 2/3 implementation:
#  - modinfo -F vermagic per module == kernel release + compiler string
#  - modinfo -F depends all resolve within the module set
#  - out/build.log shows zero modpost warnings
die "L2 module compatibility check is implemented in Phase 3"
