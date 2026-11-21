#!/usr/bin/env bash
# L2-static: final .config policy assertions (the Kconfig-level hard
# constraints from the reviewed Phase 1 plan, including the modversions rule:
# CONFIG_MODVERSIONS must stay enabled, never disabled to bypass CRC checks).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

out="$ROOT/out"
[[ -f "$out/.config" ]] || {
  echo "ERROR: missing out/.config; out/ listing (top 20):" >&2
  find "$out" -maxdepth 1 2>/dev/null | head -n20 >&2
  die "missing out/.config"
}
profile="${PROFILE:-$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["profile"])' "$out/build-info.json" 2>/dev/null || echo minimal)}"

python3 - "$out/.config" "$profile" <<'PY'
import sys

path, profile = sys.argv[1], sys.argv[2:]
profile = profile[0] if profile else 'minimal'
cfg = {}
for line in open(path, encoding='utf-8', errors='replace'):
    line = line.strip()
    if line.startswith('CONFIG_') and '=' in line:
        k, v = line.split('=', 1)
        cfg[k] = v
    elif line.startswith('# CONFIG_') and 'is not set' in line:
        cfg[line.split()[1]] = 'n'

failures = []

def want(key, expected, label):
    actual = cfg.get(key, 'unset')
    if actual != expected:
        failures.append(f'{label}: {key}={actual}, expected {expected}')

# Hard constraints from the reviewed plan.
want('CONFIG_MODVERSIONS', 'y', 'KMI hard constraint (never disable)')
want('CONFIG_KPROBES', 'y', 'SukiSU dependency')
want('CONFIG_KRETPROBES', 'y', 'SukiSU dependency')
want('CONFIG_EXT4_FS', 'y', 'SukiSU dependency')
want('CONFIG_TRACEPOINTS', 'y', 'SukiSU dependency')
want('CONFIG_HEADERS_INSTALL', 'y', 'SukiSU preinit runner')
want('CONFIG_DEBUG_INFO_BTF', 'y', 'BTF baseline')
want('CONFIG_MODULE_SIG', 'y', 'module signing baseline')

# KSU_SUSFS has no Kconfig symbol in SukiSU-Nova v3.0.0 (unconditional); the
# stock device config carried it, so report the difference rather than fail.
if 'CONFIG_KSU_SUSFS' in cfg:
    print(f'[lexing] note: CONFIG_KSU_SUSFS={cfg["CONFIG_KSU_SUSFS"]} present (v3.0.0 does not define it)')

if profile == 'minimal':
    want('CONFIG_KSU', 'y', 'root integration (route A)')
    want('CONFIG_KPM', 'n', 'minimal profile must not enable KPM')
elif profile == 'diagnostic':
    want('CONFIG_KSU', 'y', 'diagnostic profile keeps the KSU variable fixed')
    want('CONFIG_SCHED_CLASS_EXT', 'n', 'diagnostic profile disables SCX')
    if cfg.get('CONFIG_KPM') == 'y':
        failures.append('diagnostic profile must not enable KPM')
else:
    want('CONFIG_KSU', 'y', 'root integration (route A)')

ksu_syms = {k: v for k, v in cfg.items() if 'KSU' in k or 'SUSFS' in k or 'KPM' in k}
print(f'[lexing] KSU/SUSFS/KPM-related symbols: {len(ksu_syms)}')
for k in sorted(ksu_syms):
    print(f'[lexing]   {k}={ksu_syms[k]}')

if failures:
    for f in failures:
        print(f'FAIL {f}', file=sys.stderr)
    sys.exit(1)
print(f'[lexing] kconfig policy OK (profile {profile}, {len(cfg)} symbols)')
PY
