#!/usr/bin/env bash
# Build prerequisites enforced at the start of every kernel-build run. Fails
# closed. This is the single chokepoint that makes accidental Phase 0/1/2
# compilation impossible, no matter who dispatches the workflow.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

step "Phase gate"
phase_at_least phase3 || { echo "ERROR: compilation requires .phase-state >= phase3 (currently $(phase_state)). See docs/phase-gate.md." >&2; exit 1; }

step "Builder image pin"
image_ref >/dev/null

step "Environment version"
log "build environment: $(env_version)"

step "Patch manifest"
[[ -f "$ROOT/patches/PATCHES.manifest" ]] || die "missing patches/PATCHES.manifest"
count="$(manifest_patches)"
log "$count patches declared"

step "Build artifacts policy"
# Rule 13.2.7/13.6 sanity: out/ and dist/ are never committed.
git check-ignore out/ >/dev/null 2>&1 || die "out/ is not gitignored — refusing to build into a tracked tree"
git check-ignore dist/ >/dev/null 2>&1 || die "dist/ is not gitignored — refusing to build into a tracked tree"

log "build prerequisites OK: compilation unblocked for this repository state"
