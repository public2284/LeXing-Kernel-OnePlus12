#!/usr/bin/env bash
# Test harness: runs every verification check against a finished build and
# writes test-report/test-report.json and test-report.md.
#
# Every check is tagged with a verification layer so reports can never confuse
# them (project rule: format checks are not device compatibility):
#   L1-format    packaging/tooling structure (mkbootimg round-trip, zip layout)
#   L2-static    static comparison against the Phase 0 device baseline
#   L3-static    DTB/DTBO structural comparison, still not a boot test
# L4 (real device boot) is NOT part of CI — see build/checks/l4_gate.sh.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

out="$ROOT/out"
dist="$ROOT/dist"
report="$ROOT/test-report"

[[ -d "$out" ]] || die "missing out/ — nothing to verify"
[[ -d "$dist" ]] || die "missing dist/ — nothing to verify"

mkdir -p "$report"
statuses="$report/statuses.tsv"
: > "$statuses"

run_check() {
  local name="$1" layer="$2" script="$3" state
  echo; echo "--- $name ($layer) ---"
  if bash "$script" >"$report/$name.log" 2>&1; then
    state=PASS
  else
    state=FAIL
  fi
  printf '%s\t%s\t%s\n' "$name" "$layer" "$state" >> "$statuses"
  echo "$state — log: test-report/$name.log"
}

step "Running verification suite"

run_check image_structure   L1-format build/checks/image_structure.sh
run_check package_structure L1-format build/checks/package_structure.sh
run_check sha256            L1-format build/checks/sha256_verify.sh
run_check device_params     L2-static build/checks/device_params.sh
run_check kconfig_diff      L2-static build/checks/kconfig_diff.sh
run_check kmi               L2-static build/checks/kmi_check.sh
run_check symbol_deps       L2-static build/checks/symbol_deps.sh
run_check module_compat     L2-static build/checks/module_compat.sh
run_check dtb               L3-static build/checks/dtb_check.sh

step "Write test report"
python3 - "$statuses" "$report" <<'PY'
import json, sys, pathlib

statuses = pathlib.Path(sys.argv[1])
report = pathlib.Path(sys.argv[2])

checks = []
for line in statuses.read_text(encoding='utf-8').splitlines():
    if not line.strip():
        continue
    name, layer, state = line.split('\t')
    log_path = f'test-report/{name}.log'
    tail = ''
    log = report / f'{name}.log'
    if log.exists():
        tail = '\n'.join(log.read_text(encoding='utf-8', errors='replace').splitlines()[-8:])
    checks.append({
        'name': name, 'layer': layer, 'state': state,
        'log': log_path, 'tail': tail,
        'on_device_verification': 'PENDING',   # L4: always reported, never claimed by CI
    })

failed = [c for c in checks if c['state'] != 'PASS']
payload = {
    'checks': checks,
    'summary': {
        'total': len(checks),
        'passed': len(checks) - len(failed),
        'failed': len(failed),
        'device_boot_verified': False,   # only an on-device record flips this
    },
}
(report / 'test-report.json').write_text(
    json.dumps(payload, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

lines = ['# Test report', '',
         '| check | layer | state |', '|---|---|---|']
for c in checks:
    lines.append(f"| {c['name']} | {c['layer']} | {c['state']} |")
lines += ['',
          'L4 real-device verification is not part of CI.',
          'A release additionally requires a PASS record in verification/device/',
          '']
(report / 'test-report.md').write_text('\n'.join(lines), encoding='utf-8')

if failed:
    print(f"{len(failed)} check(s) failed", file=sys.stderr)
    sys.exit(1)
print(f"all {len(checks)} checks passed")
PY
