#!/usr/bin/env bash
# Integrate the pinned SukiSU-Nova tree into the kernel tree — route A
# (built-in, CONFIG_KSU=y).
#
# This is the auditable replacement for SukiSU-Nova's kernel/setup.sh at the
# pinned commit: setup.sh performs unversioned network operations
# (git clone + git pull + "latest tag" checkout, project rule 13.4.2), so it is
# never executed. The Makefile/Kconfig wiring it applies is delivered as the
# reviewed patch patches/0100.patch; this script only creates the
# drivers/kernelsu symlink into the pinned submodule and verifies the result.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

kernel="$ROOT/kernel"
ksu="$ROOT/sukisu-nova"

[[ -f "$kernel/Makefile" ]] || die "kernel submodule not checked out (kernel/Makefile missing)"
[[ -f "$ksu/kernel/Kbuild" ]] || die "sukisu-nova submodule not checked out (kernel/Kbuild missing)"

step "Integrate SukiSU-Nova (route A, built-in)"

ln -sfn ../../sukisu-nova/kernel "$kernel/drivers/kernelsu"

[[ -f "$kernel/drivers/kernelsu/Kbuild" ]] || die "symlink broken: drivers/kernelsu/Kbuild not reachable"
grep -qE 'obj-\$\(CONFIG_KSU\)[[:space:]]*\+=[[:space:]]*kernelsu' "$kernel/drivers/Makefile" \
  || die "drivers/Makefile missing obj-\$(CONFIG_KSU) line — apply patches/0100.patch first"
grep -q 'source "drivers/kernelsu/Kconfig"' "$kernel/drivers/Kconfig" \
  || die "drivers/Kconfig missing the kernelsu source line — apply patches/0100.patch first"

ksu_commit="$(git -C "$ksu" rev-parse HEAD 2>/dev/null || echo unknown)"
log "drivers/kernelsu -> sukisu-nova/kernel (commit $ksu_commit)"
