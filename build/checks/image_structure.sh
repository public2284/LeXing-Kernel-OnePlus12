#!/usr/bin/env bash
# L1-format: the flashable zip has the AnyKernel3 layout and the staged Image
# is a valid ARM64 kernel image.
#
# Passing proves packaging integrity ONLY. It says nothing about device
# compatibility - that requires L2/L3 and, ultimately, L4 on-device boot.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
[[ -d "$dist" ]] || die "missing dist/ - run package_anykernel.sh first"

zips=( "$dist"/*.zip )
[[ ${#zips[@]} -eq 1 ]] || die "expected exactly one zip in dist/, found ${#zips[@]}"
zip="${zips[0]}"

status=0
for entry in Image anykernel.sh META-INF/com/google/android/update-binary tools/ak3-core.sh; do
  if ! unzip -l "$zip" "$entry" | grep -q "$entry"; then
    echo "FAIL zip missing entry: $entry"
    status=1
  fi
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -q -p "$zip" Image > "$tmp/Image" 2>/dev/null || { echo "FAIL cannot extract Image from zip"; exit 1; }
size="$(stat -c %s "$tmp/Image")"
if [[ $size -lt 4194304 ]]; then
  echo "FAIL Image is only $size bytes, below the 4 MiB sanity floor"
  status=1
fi
# ARM64 kernel Image magic: bytes 56..59 == "ARMd" (41 52 4d 64).
magic="$(dd if="$tmp/Image" bs=1 skip=56 count=4 status=none | od -An -tx1 | tr -d ' \n')"
if [[ "$magic" != "41524d64" ]]; then
  echo "FAIL Image magic is $magic, expected 41524d64 (ARMd)"
  status=1
fi

# No partition image other than the kernel may be packaged (route A).
for entry in init_boot dtbo vendor_boot vbmeta; do
  if unzip -l "$zip" | grep -qE "\b$entry\b"; then
    echo "FAIL zip contains a $entry artifact - route A packages the kernel only"
    status=1
  fi
done

[[ $status -eq 0 ]] || die "image structure failed"
log "image structure OK: $(basename "$zip"), Image ${size} bytes, ARM64 magic present, single-entry layout"