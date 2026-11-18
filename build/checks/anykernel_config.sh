#!/usr/bin/env bash
# AnyKernel3 config sanity: once the AnyKernel3 submodule is configured, its
# config must declare the device and kernel string before any packaging. Skips
# cleanly while the submodule is absent (Phase 0/1).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

cfg="$ROOT/AnyKernel3/config"
if [[ ! -f "$cfg" ]]; then
  log "AnyKernel3 submodule not configured yet: skipping (Phase 2 activates this check)"
  exit 0
fi

status=0
for key in kernel.string; do
  if ! grep -qE "^${key}=/dev/.+|${key}=\S" "$cfg" || grep -qE "^${key}=\s*$" "$cfg"; then
    echo "FAIL AnyKernel3/config: empty '$key'"
    status=1
  fi
done
for key in device.name1; do
  if ! grep -qE "^${key}=.+" "$cfg"; then
    echo "FAIL AnyKernel3/config: missing '$key'"
    status=1
  fi
done

if grep -nE 'blkdev=' "$cfg" | grep -qE '^[0-9]+:.*=\s*$'; then
  echo "FAIL AnyKernel3/config: empty block device path"
  status=1
fi

[[ "$status" -eq 0 ]] || die "AnyKernel3 config incomplete"
log "AnyKernel3 config OK"
