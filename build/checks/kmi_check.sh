#!/usr/bin/env bash
# L2-static: KMI (Kernel Module Interface) stability, CI-side part.
#
# Checks the parts that do not need device data:
#   - kernel release carries the android14-11 KMI generation
#   - Module.symvers exists and is non-trivial
#   - every symbol in the tree's protected-exports list is exported
#
# The symbol-CRC comparison against the device's vendor modules runs in
# module_compat.sh and stays PENDING until the device baseline is collected.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

out="$ROOT/out"
[[ -f "$out/Module.symvers" ]] || die "missing out/Module.symvers"

release="$(cat "$out/include/config/kernel.release" 2>/dev/null || true)"
case "$release" in
  *android14-11*) log "KMI generation OK: $release" ;;
  *) die "kernel release lacks android14-11: ${release:-unknown}" ;;
esac

protect="$ROOT/kernel/android/abi_gki_protected_exports_aarch64"
[[ -f "$protect" ]] || die "missing protected-exports list at $protect"

python3 - "$out/Module.symvers" "$protect" <<'PY'
import sys

symvers_path, protect_path = sys.argv[1], sys.argv[2]
exports = set()
for line in open(symvers_path, encoding='utf-8', errors='replace'):
    parts = line.split('\t')
    if len(parts) >= 3 and parts[1]:
        exports.add(parts[1])

protected = [l.strip() for l in open(protect_path, encoding='utf-8') if l.strip()]
missing = [s for s in protected if s not in exports]
print(f'[lexing] Module.symvers exports: {len(exports)}')
print(f'[lexing] protected symbols: {len(protected)}, missing: {len(missing)}')
if missing:
    print('FAIL missing protected exports (ABI regression):', file=sys.stderr)
    for s in missing[:40]:
        print(f'  - {s}', file=sys.stderr)
    sys.exit(1)
print('[lexing] protected-exports OK: all protected symbols exported')
PY
log "KMI check OK (CI side; device CRC comparison stays PENDING)"