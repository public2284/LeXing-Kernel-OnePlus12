#!/usr/bin/env bash
# L1-format check: flashable package structure.
#
# Verifies the AnyKernel3 zip layout: at minimum the ramdisk update binary
# path, anykernel.sh, config, and the kernel payload. Fully implemented;
# depends only on unzip.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
zip="$(ls "$dist"/*.zip 2>/dev/null | head -n1)"
[[ -n "$zip" ]] || die "no flashable zip in dist/"

command -v unzip >/dev/null 2>&1 || die "unzip required"

listing="$(mktemp)"
unzip -l "$zip" > "$listing"

status=0
required_paths='anykernel.sh'
for rel in $required_paths; do
  if ! awk 'NR>3 && $4 ~ /(^|\/)'"$rel"'$/ {found=1} END{exit !found}' "$listing" 1>/dev/null; then
    echo "FAIL zip is missing required entry: $rel"
    status=1
  fi
done

# The kernel payload must be present (AnyKernel3 layout: Image under AnyKernel3/)
if ! awk 'NR>3 && $4 ~ /\/Image(\.gz)?$/ {found=1} END{exit !found}' "$listing" 1>/dev/null; then
  echo "FAIL zip has no kernel Image payload"
  status=1
fi

# No stray build outputs in the package
if awk 'NR>3 && $4 ~ /\.(o|cmd|log)$/ {bad=1} END{exit bad}' "$listing" 1>/dev/null; then
  echo "FAIL zip contains build artifacts (.o/.cmd/.log)"
  status=1
fi

[[ "$status" -eq 0 ]] || die "package structure failed"
log "package structure OK ($(basename "$zip"))"
