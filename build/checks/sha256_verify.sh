#!/usr/bin/env bash
# L1-format: SHA256SUMS matches every file in dist/ (rule 13.4.4).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
[[ -f "$dist/SHA256SUMS" ]] || die "missing dist/SHA256SUMS"

( cd "$dist" && sha256sum -c SHA256SUMS )
log "sha256 OK: all dist/ files verified"