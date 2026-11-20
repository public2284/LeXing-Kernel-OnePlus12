#!/usr/bin/env bash
# Package the built kernel into an AnyKernel3 flashable zip.
#
# Reads out/ and configs/anykernel3.env, stages the pinned AnyKernel3 tree
# (plus Image), injects the device/block overrides, and writes dist/ with the
# zip, SHA256SUMS, RELEASE_NOTES.md and a copy of build-info.json.
#
# Route A: only the boot partition is written (block=boot). init_boot, dtbo
# and vendor_boot are never touched by this package.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

out="$ROOT/out"
ak3="$ROOT/AnyKernel3"
dist="$ROOT/dist"
cfg="$ROOT/configs/anykernel3.env"

[[ -d "$out" ]] || die "no out/ directory - run build_kernel.sh first"
[[ -f "$out/build-info.json" ]] || die "no out/build-info.json - run build_kernel.sh first"
[[ -d "$ak3" ]] || die "AnyKernel3 submodule not checked out"
[[ -f "$cfg" ]] || die "missing $cfg"

SUFFIX="${SUFFIX:-}"

get() { grep -E "^$1=" "$cfg" | head -n1 | cut -d= -f2-; }
set_prop() {  # set_prop <file> <key> <value>
  sed -i "s|^$1=.*|$1=$2|" "$3"
}

step "Stage AnyKernel3 payload"
rm -rf "$dist"
mkdir -p "$dist/.stage"
cp -a "$ak3/." "$dist/.stage/"
rm -rf "$dist/.stage/.git"
[[ -f "$dist/.stage/anykernel.sh" ]] || die "staged AnyKernel3 missing anykernel.sh"
[[ -f "$out/arch/arm64/boot/Image" ]] || die "missing out/arch/arm64/boot/Image"
cp "$out/arch/arm64/boot/Image" "$dist/.stage/Image"

step "Apply device and partition overrides"
ak="$dist/.stage/anykernel.sh"
set_prop kernel.string        "$(get KERNEL_STRING)"  "$ak"
# AnyKernel3 ships five device.name* slots; fill the ones we have values for.
i=1
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  set_prop "device.name$i" "$name" "$ak"
  i=$((i+1))
  [[ $i -le 5 ]] || break
done < <(get DEVICE_NAME1; get DEVICE_NAME2; get DEVICE_NAME3; get DEVICE_NAME4; get DEVICE_NAME5)
set_prop do.devicecheck "$(get DO_DEVICECHECK)" "$ak"
set_prop block           "$(get BLOCK)"           "$ak"
set_prop is_slot_device  "$(get IS_SLOT_DEVICE)"  "$ak"

step "Build flashable zip"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["kernel_release"])' "$out/build-info.json")"
zipname="LeXing-Kernel_${version}${SUFFIX}.zip"
( cd "$dist/.stage" && zip -r -X -q "../$zipname" . )
rm -rf "$dist/.stage"

step "Write manifest and notes"
cp "$out/build-info.json" "$dist/"
{
  echo "# LeXing Kernel ${version}${SUFFIX}"
  echo
  echo "- Kernel release: ${version}"
  echo "- Install target: boot partition only (block=boot, A/B slot aware)."
  echo "- Build date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Source, toolchain, patch and environment pins: see build-info.json."
  echo
  echo "## Verification state"
  echo
  echo "CI covers L1-L3 (format, static, DTB structure) only. This zip has NOT"
  echo "been booted on a device. Do not flash without the Phase 3 backup and a"
  echo "recorded L4 result in verification/device/."
  echo
  echo "## Rollback"
  echo
  echo "Restore the stock boot image backed up before flashing (dd to the"
  echo "boot partition of the inactive slot, or reflash via fastboot)."
} > "$dist/RELEASE_NOTES.md"

( cd "$dist" && sha256sum "$zipname" build-info.json RELEASE_NOTES.md > SHA256SUMS )

step "Verify package integrity"
unzip -t "$dist/$zipname" >/dev/null
( cd "$dist" && sha256sum -c SHA256SUMS ) >/dev/null
log "dist ready: $dist/$zipname ($(du -h "$dist/$zipname" | cut -f1))"
