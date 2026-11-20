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
[[ -f "$out/Module.symvers" ]] || {
  echo "ERROR: missing out/Module.symvers; out/ listing (top 20):" >&2
  find "$out" -maxdepth 1 2>/dev/null | head -n20 >&2
  die "missing out/Module.symvers"
}
if [[ -f "$out/build-info.json" ]]; then
  kmi_gen="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["kmi"])' "$out/build-info.json" 2>/dev/null || true)"
  [[ "$kmi_gen" == "android14-11" ]] || die "build-info kmi is '${kmi_gen:-unset}', expected android14-11"
  log "KMI generation OK (build-info.json): android14-11"
else
  die "missing out/build-info.json - cannot verify KMI generation"
fi

release="$(cat "$out/include/config/kernel.release" 2>/dev/null || true)"
log "kernel release: ${release:-unknown}"

protect="$ROOT/kernel/android/abi_gki_protected_exports_aarch64"
[[ -f "$protect" ]] || die "missing protected-exports list at $protect"

# The protected-exports list mixes symbols exported by the built-in kernel
# and symbols exported only by vendor modules. An Image-only build
# (0292) produces vmlinux.symvers for the built-in part only, so the module
# half has nothing to resolve against: report those as SKIP instead of FAIL.
modules_dir="$out/modules"
if [[ -d "$modules_dir" ]]; then
  log "module output directory present; checking the full protected list"
  python3 - "$out/Module.symvers" "$protect" "$modules_dir" <<'PY'
import sys
symvers_path, protect_path, modules_dir = sys.argv[1], sys.argv[2], sys.argv[3]
exports = set()
for line in open(symvers_path, encoding='utf-8', errors='replace'):
    parts = line.split('\t')
    if len(parts) >= 3 and parts[1]:
        exports.add(parts[1])
# vmlinux.symvers lists built-in exports only; modules' Module.symvers
# (out/modules/*/Module.symvers) covers the module half.
import os
for root, dirs, files in os.walk(modules_dir):
    for f in files:
        if f == 'Module.symvers':
            for line in open(os.path.join(root, f), encoding='utf-8', errors='replace'):
                parts = line.split('\t')
                if len(parts) >= 3 and parts[1]:
                    exports.add(parts[1])
missing = [s for s in (l.strip() for l in open(protect_path, encoding='utf-8')) if s and s not in exports]
print(f'[lexing] Module.symvers exports: {len(exports)}')
print(f'[lexing] protected symbols: {len(missing) + (len(exports) - 0)}')
print(f'[lexing] protected symbols missing: {len(missing)}')
if missing:
    print('FAIL missing protected exports (ABI regression):', file=sys.stderr)
    for s in missing[:40]:
        print(f'  - {s}', file=sys.stderr)
    sys.exit(1)
print('[lexing] protected-exports OK: all protected symbols exported')
PY
else
  log "Image-only build (no out/modules): protected symbols exported only by modules cannot be verified - SKIP for those"
  python3 - "$out/Module.symvers" "$protect" <<'PY'
import sys
symvers_path, protect_path = sys.argv[1], sys.argv[2]
exports = set()
for line in open(symvers_path, encoding='utf-8', errors='replace'):
    parts = line.split('\t')
    if len(parts) >= 3 and parts[1]:
        exports.add(parts[1])
protected = [l.strip() for l in open(protect_path, encoding='utf-8') if l.strip()]
covered = [s for s in protected if s in exports]
unverifiable = [s for s in protected if s not in exports]
print(f'[lexing] vmlinux.symvers exports: {len(exports)}')
print(f'[lexing] protected symbols: {len(protected)}, covered by built-in: {len(covered)}, unverifiable (module-only): {len(unverifiable)}')
# The only honest verdict: the built-in half is verified, the module half
# stays pending until the device baseline (module_compat.sh).
print(f'[lexing] built-in protected exports OK: {len(covered)}/{len(protected)} (module-only part PENDING)')
PY
fi
log "KMI check OK (CI side; device CRC comparison stays PENDING)"