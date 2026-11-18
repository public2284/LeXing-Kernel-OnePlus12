#!/usr/bin/env bash
# Syntax and lint check on every shell script. Uses shellcheck when the runner
# has it (GitHub ubuntu images ship it), falls back to bash -n. Real check.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

status=0
while IFS= read -r f; do
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S warning "$f" || status=1
  else
    bash -n "$f" || { echo "FAIL syntax: $f"; status=1; }
  fi
done < <(find "$ROOT/build" -type f -name '*.sh' | sort)

[[ "$status" -eq 0 ]] || die "shell checks failed"
log "shell checks passed ($(find "$ROOT/build" -type f -name '*.sh' | wc -l) scripts, shellcheck=$(command -v shellcheck >/dev/null 2>&1 && echo yes || echo 'bash -n fallback)')"
