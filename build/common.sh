#!/usr/bin/env bash
# Shared helpers for LeXing Kernel build and check scripts.
# Sourced, never executed directly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors are deliberately absent: CI logs are plain text, output must be greppable.
die()  { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[lexing] $*"; }
step() { echo; echo "=== $* ==="; }

phase_state() {
  # Echoes the current project phase from .phase-state (phase0..phase5).
  local f="$ROOT/.phase-state" v
  [[ -f "$f" ]] || die "missing $f"
  v="$(grep -E '^PHASE=' "$f" | head -n1 | cut -d= -f2-)"
  [[ -n "$v" ]] || die "empty PHASE= in $f"
  echo "$v"
}

phase_at_least() {
  # phase_at_least <target> — succeeds when the project phase is >= target.
  local target="$1" current
  local -A order=([phase0]=0 [phase1]=1 [phase2]=2 [phase3]=3 [phase4]=4 [phase5]=5)
  current="$(phase_state)"
  [[ -n "${order[$target]:-}" ]] || die "unknown phase target: $target"
  [[ -n "${order[$current]:-}" ]] || die "unknown phase in .phase-state: $current"
  (( ${order[$current]} >= ${order[$target]} ))
}

image_ref() {
  # Echoes the pinned builder image reference from build/docker/image.lock.
  local f="$ROOT/build/docker/image.lock" ref
  [[ -f "$f" ]] || die "missing $f"
  ref="$(grep -E '^IMAGE_REF=' "$f" | head -n1 | cut -d= -f2-)"
  [[ -n "$ref" ]] || die "build/docker/image.lock has no IMAGE_REF yet (fill it after a toolchain-image.yml run)"
  echo "$ref"
}

env_version() {
  # Echoes the Build Environment Release version (e.g. b0).
  local f="$ROOT/build/docker/ENV_VERSION" v
  [[ -f "$f" ]] || die "missing $f"
  v="$(grep -E '^ENV_VERSION=' "$f" | head -n1 | cut -d= -f2-)"
  [[ -n "$v" ]] || die "empty ENV_VERSION= in $f"
  echo "$v"
}

profile_fragment() {
  # profile_fragment <name> — echoes the fragment path, failing if it is missing.
  local name="$1" f="$ROOT/build/profiles/$1.fragment"
  [[ -f "$f" ]] || die "unknown build profile: $name"
  echo "$f"
}

manifest_patches() {
  # Echoes the number of patch entries declared in patches/PATCHES.manifest.
  local f="$ROOT/patches/PATCHES.manifest"
  if [[ ! -f "$f" ]]; then echo 0; return 0; fi
  python3 - "$f" <<'PY'
import sys, yaml
with open(sys.argv[1], encoding='utf-8') as fh:
    data = yaml.safe_load(fh) or {}
print(len(data.get('patches', []) or []))
PY
}

device_record() {
  # device_record <version> — echoes the path of the L4 record for a tag.
  echo "$ROOT/verification/device/$1.md"
}
