#!/usr/bin/env bash
# L2-static: vendor-module symbol dependency resolution.
#
# Requires the device baseline: the UND/CRC table of the 439 stock vendor
# modules, collected during the Phase 3 device backup step (which needs the
# device and a human present). CI cannot claim this without that baseline, so
# the check reports SKIP (exit 3) rather than passing on no evidence.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

baseline="$ROOT/configs/kmi"
if [[ ! -d "$baseline" ]]; then
  echo "SKIP symbol_deps: no device module baseline (configs/kmi/ absent) - run the Phase 3 device backup step first"
  exit 3
fi
[[ -f "$ROOT/out/Module.symvers" ]] || die "missing out/Module.symvers"

# Baseline present: resolve every required symbol against Module.symvers.
python3 - "$ROOT/configs/kmi" "$ROOT/out/Module.symvers" <<'PY'
import pathlib, sys

baseline, symvers = sys.argv[1], sys.argv[2]
required = set()
for f in pathlib.Path(baseline).glob('*.und'):
    for line in f.read_text(encoding='utf-8', errors='replace').splitlines():
        line = line.strip()
        if line:
            required.add(line)
if not required:
    print('SKIP symbol_deps: baseline directory exists but contains no symbols')
    sys.exit(3)

exports = {l.split('\t')[1] for l in open(symvers, encoding='utf-8', errors='replace')
           if len(l.split('\t')) >= 3 and l.split('\t')[1]}
missing = sorted(required - exports)
print(f'[lexing] required symbols: {len(required)}, exported: {len(exports)}, missing: {len(missing)}')
if missing:
    print('FAIL unresolved vendor module symbols:', file=sys.stderr)
    for s in missing[:40]:
        print(f'  - {s}', file=sys.stderr)
    sys.exit(1)
print('[lexing] symbol deps OK: every required symbol is exported')
PY