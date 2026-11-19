#!/usr/bin/env bash
# L2-static: the package targets exactly this device and writes exactly the
# boot partition. Asserts on the staged anykernel.sh and build-info.json.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
[[ -d "$dist" ]] || die "missing dist/"
zips=( "$dist"/*.zip )
[[ ${#zips[@]} -eq 1 ]] || die "expected exactly one zip in dist/"
zip="${zips[0]}"

ak="$(unzip -q -p "$zip" anykernel.sh)"

status=0
val() { echo "$ak" | grep -E "^$1=" | head -n1 | cut -d= -f2-; }

block="$(val block)"
[[ "$block" == "boot" ]] || { echo "FAIL block=$block, must be boot (route A writes boot only)"; status=1; }

slot="$(val is_slot_device)"
[[ "$slot" == "auto" ]] || { echo "FAIL is_slot_device=$slot, must be auto (A/B device)"; status=1; }

check="$(val do.devicecheck)"
[[ "$check" == "1" ]] || { echo "FAIL do.devicecheck=$check, must be 1 (installer must abort on mismatch)"; status=1; }

names="$(echo "$ak" | grep -cE '^device\.name[1-5]=[^[:space:]]')"
[[ $names -ge 1 ]] || { echo "FAIL no device.name* set"; status=1; }
for n in $(echo "$ak" | grep -oE '^device\.name[1-5]=.*' | cut -d= -f2-); do
  log "device name entry: $n"
done

# No partition other than boot may appear in the install section.
for forbidden in init_boot dtbo vendor_boot vbmeta super; do
  if echo "$ak" | grep -qE "^[[:space:]]*block=.*$forbidden"; then
    echo "FAIL anykernel.sh targets $forbidden"
    status=1
  fi
done

release="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["kernel_release"])' "$dist/build-info.json")"
case "$release" in
  *android14-11*) log "kernel release KMI string OK: $release" ;;
  *) echo "FAIL kernel release lacks android14-11: $release"; status=1 ;;
esac

[[ $status -eq 0 ]] || die "device params failed"
log "device params OK: block=boot, A/B aware, device check on, KMI android14-11"