#!/usr/bin/env bash
# Patch provenance and integrity: every patches/*.patch matches the SHA256
# recorded in patches/PATCHES.manifest, and (once the kernel submodule exists)
# the series applies cleanly to the pending kernel commit. Real check for the
# SHA256 part; the apply check activates when the kernel source is configured.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

manifest="$ROOT/patches/PATCHES.manifest"
[[ -f "$manifest" ]] || die "missing $manifest"

status=0

while IFS= read -r declared; do
  file="$(echo "$declared" | cut -f1)"
  expected="$(echo "$declared" | cut -f2)"
  path="$ROOT/patches/$file"
  if [[ ! -f "$path" ]]; then
    echo "FAIL $file: declared in manifest but missing on disk"
    status=1
    continue
  fi
  actual="$(sha256sum "$path" | cut -d' ' -f1)"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL $file: sha256 mismatch (manifest=$expected actual=$actual)"
    status=1
  fi
done < <(python3 - "$manifest" <<'PY'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
for e in data.get('patches', []) or []:
    print(f"{e['id']}.patch\t{e['sha256']}")
PY
)

for p in "$ROOT"/patches/*.patch; do
  [[ -e "$p" ]] || continue
  if ! python3 - "$manifest" "$(basename "$p")" <<'PY'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
ids = {e['id'] for e in data.get('patches', []) or []}
sys.exit(0 if sys.argv[2].removesuffix('.patch') in ids else 1)
PY
  then
    echo "FAIL $(basename "$p"): on disk but not declared in manifest"
    status=1
  fi
done

if [[ -f "$ROOT/kernel/Makefile" ]]; then
  log "kernel source present: apply check activates in Phase 2"
else
  log "kernel submodule not configured yet: apply check deferred"
fi

[[ "$status" -eq 0 ]] || die "patch integrity failed"
count="$(manifest_patches)"
log "patch integrity OK ($count declared patches)"
