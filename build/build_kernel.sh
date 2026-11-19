#!/usr/bin/env bash
# LeXing Kernel build orchestration.
#
# Environment: PROFILE (minimal|full|debug|experimental), CCACHE (true|false).
# Produces out/ with the kernel image, modules, config, logs and build-info.json.
#
# Fails closed: every stage that depends on Phase 1/2 outputs (patch
# application, defconfig merge, compilation) refuses to run until those outputs
# exist, and compilation additionally requires .phase-state >= phase3.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

PROFILE="${PROFILE:-minimal}"

step "0/7 Validate profile"
fragment="$(profile_fragment "$PROFILE")"
log "profile=$PROFILE fragment=$fragment"

step "1/7 Phase gate"
phase_at_least phase3 || die "compilation blocked: .phase-state is '$(phase_state)', needs phase3 (see docs/phase-gate.md)"

step "2/7 Kernel source pin"
# The kernel source arrives as a submodule pinned to a commit in .gitmodules.
# Phase 0/1 fills in the actual repository; until then there is nothing to build.
if [[ ! -f "$ROOT/kernel/Kbuild" && ! -f "$ROOT/kernel/Makefile" ]]; then
  die "kernel source not configured yet (submodule 'kernel' is a Phase 2 task after Phase 0/1 outputs)"
fi

step "3/7 Apply patches"
# Phase 2 implementation: iterate patches/PATCHES.manifest in order, apply each
# patch from patches/, verify applied hunks, abort the whole build on any
# conflict and leave no half-patched tree. Integrity of the manifest itself is
# already enforced by patch_integrity.sh on every pull request.
if [[ "$(manifest_patches)" -gt 0 ]]; then
  die "patch application is implemented in Phase 2 together with the first real patch"
fi
log "no patches declared yet"

step "4/7 Merge build profile into defconfig"
# Phase 1/2 implementation: take the device defconfig from configs/, merge the
# profile fragment with the kernel's merge_config.sh, and write out/.config.
die "defconfig merge is implemented in Phase 1/2 after the Feature Registry and device config exist"

step "5/7 Compile"
# Phase 2/3 implementation: Image + modules + dtb with the pinned clang from
# the builder image, logs tee'd into out/build.log, ccache per the input.
die "compilation is implemented in Phase 2/3"

step "6/7 Collect outputs"
# Emits out/build-info.json: kernel release, profile, head commit, all
# submodule pins, patch list, clang version, builder image digest,
# ENV_VERSION (docs/VERSIONING.md), timestamps.
die "output collection is implemented in Phase 2/3"

step "7/7 Done"
log "build finished (not reached in Phase 0)"
