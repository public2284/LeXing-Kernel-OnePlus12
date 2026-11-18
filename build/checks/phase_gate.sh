#!/usr/bin/env bash
# phase_gate.sh <target> — exits 0 only when .phase-state is at least <target>.
# Used by build prerequisites and, indirectly, documented in docs/phase-gate.md.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

target="${1:-phase3}"
if phase_at_least "$target"; then
  log "phase gate OPEN: $(phase_state) >= $target"
else
  echo "ERROR: phase gate CLOSED: .phase-state is '$(phase_state)', needs $target" >&2
  echo "See docs/phase-gate.md. Compilation stays blocked until the project reaches Phase 3 with maintainer approval." >&2
  exit 1
fi
