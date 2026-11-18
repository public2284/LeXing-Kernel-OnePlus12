#!/usr/bin/env bash
# SHA256 verification (project rule 13.4.4/13.6).
#
#   sha256_verify.sh <dir>   — verify <dir>/SHA256SUMS against the files in <dir>
#
# The release path runs this twice: once after packaging, once after the
# approval gate, on freshly downloaded artifacts.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dir="${1:-$ROOT/dist}"
sums="$dir/SHA256SUMS"
[[ -f "$sums" ]] || die "missing $sums"

( cd "$dir" && sha256sum -c SHA256SUMS )
log "SHA256 OK for $dir ($(wc -l < "$sums") files)"
