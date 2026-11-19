#!/usr/bin/env bash
# L2-static: vendor module compatibility - the symbol CRC comparison against
# the device's stock modules (the device baseline from the Phase 3 backup
# step). This is the KMI hard constraint 2/4 check: CRC mismatch must block
# release, and modversions must never be disabled to bypass it.
#
# CI cannot run it without the device baseline, so it reports SKIP (exit 3)
# until configs/kmi/ holds the extracted __versions tables.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

baseline="$ROOT/configs/kmi"
if [[ ! -d "$baseline" ]] || [[ -z "$(find "$baseline" -name '*.crc' 2>/dev/null | head -n1)" ]]; then
  echo "SKIP module_compat: no device CRC baseline (configs/kmi/*.crc absent) - device backup step required; release gate stays closed"
  exit 3
fi

python3 - "$baseline" "$ROOT/out/Module.symvers" <<'PY'
import pathlib, sys

baseline, symvers = sys.argv[1], sys.argv[2]
need = {}
for f in pathlib.Path(baseline).glob('*.crc'):
    for line in f.read_text(encoding='utf-8', errors='replace').splitlines():
        parts = line.split('\t')
        if len(parts) == 2:
            need[parts[0]] = parts[1]
if not need:
    print('SKIP module_compat: baseline has no CRC entries')
    sys.exit(3)

have = {}
for line in open(symvers, encoding='utf-8', errors='replace'):
    parts = line.split('\t')
    if len(parts) >= 3 and parts[1]:
        have[parts[1]] = parts[0]

mismatch, missing = {}, []
for sym, crc in need.items():
    if sym not in have:
        missing.append(sym)
    elif have[sym] != crc:
        mismatch[sym] = (crc, have[sym])
print(f'[lexing] device CRCs: {len(need)}, missing: {len(missing)}, mismatched: {len(mismatch)}')
if missing or mismatch:
    print('FAIL vendor module compatibility:', file=sys.stderr)
    for s in missing[:20]:
        print(f'  missing: {s}', file=sys.stderr)
    for s, (want, got) in list(mismatch.items())[:20]:
        print(f'  crc diff: {s} device={want} built={got}', file=sys.stderr)
    sys.exit(1)
print('[lexing] module compat OK: all device CRCs match')
PY