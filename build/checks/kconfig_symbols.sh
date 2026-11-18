#!/usr/bin/env bash
# Kconfig symbol existence: every CONFIG_ symbol referenced by a build profile
# fragment must exist in the kernel source's Kconfig files. Runs whenever the
# kernel submodule is configured; skips with a clear message when it is not.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

kernel="$ROOT/kernel"
[[ -f "$kernel/Makefile" ]] || { log "kernel submodule not configured yet: skipping (Phase 2 activates this check)"; exit 0; }

symbols="$(grep -rhoE '^\s*CONFIG_[A-Za-z0-9_]+' "$ROOT"/build/profiles/*.fragment | tr -d ' ' | sort -u || true)"
[[ -n "$symbols" ]] || { log "no CONFIG symbols in profile fragments yet"; exit 0; }

status=0
while IFS= read -r sym; do
  if ! grep -rqE "^config ${sym#CONFIG_}\$|config ${sym#CONFIG_}\b" "$kernel" --include='Kconfig*' 2>/dev/null; then
    echo "FAIL symbol $sym not found in kernel Kconfig files"
    status=1
  fi
done <<< "$symbols"

[[ "$status" -eq 0 ]] || die "unknown Kconfig symbols in profiles"
log "kconfig symbols OK ($(echo "$symbols" | wc -l) symbols validated)"
