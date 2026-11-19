#!/usr/bin/env bash
# L3-static: DTB/DTBO structural comparison against the device's extracted
# blobs. Route A does not touch dtbo, so the CI-side assertion is that no
# dtbo/dtb artifact entered the package; the device-side comparison stays
# PENDING until the Phase 3 backup provides the reference blobs.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
[[ -d "$dist" ]] || die "missing dist/"
zips=( "$dist"/*.zip )
zip="${zips[0]}"

if unzip -l "$zip" | grep -qE '\b(dtbo|dtbo\.img)\b'; then
  echo "FAIL package contains a dtbo artifact - route A must not ship one"
  exit 1
fi

baseline="$ROOT/configs/dtb"
if [[ ! -d "$baseline" ]]; then
  echo "SKIP dtb_check: no device DTB baseline (configs/dtb/ absent) - dump dtbo in the Phase 3 backup step"
  exit 3
fi

if [[ ! -d "$ROOT/out/arch/arm64/boot/dts" ]]; then
  echo "SKIP dtb_check: built tree has no dts output to compare"
  exit 3
fi

echo "dtb comparison against $baseline is not yet implemented (Phase 3 follow-up)"
exit 3