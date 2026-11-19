#!/usr/bin/env bash
# Test harness: runs every verification check against a finished build and
# writes test-report/test-report.json and test-report.md.
#
# Every check is tagged with a verification layer so reports can never confuse
# them (project rule: format checks are not device compatibility):
#   L1-format    packaging/tooling structure (zip layout, Image magic, SHA256)
#   L2-static    static comparison against the Phase 0 device baseline
#   L3-static    DTB/DTBO structural comparison, still not a boot test
# L4 (real device boot) is NOT part of CI — see build/checks/l4_gate.sh.
#
# Check exit codes: 0 = PASS, 3 = SKIP (missing device baseline, reported
# honestly, never counted as a pass), anything else = FAIL.
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
  local name="$1" layer="$2" script="$3" state rc
  echo; echo "--- $name ($layer) ---"
  set +e
  bash "$script" >"$report/$name.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0) state=PASS ;;
    3) state=SKIP ;;
    *) state=FAIL ;;
  esac
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

failed = [c for c in checks if c['state'] == 'FAIL']
skipped = [c for c in checks if c['state'] == 'SKIP']
payload = {
    'checks': checks,
    'summary': {
        'total': len(checks),
        'passed': len(checks) - len(failed) - len(skipped),
        'skipped': len(skipped),
        'failed': len(failed),
        'device_boot_verified': False,   # only an on-device record flips this
        'skipped_reason': 'SKIP = device baseline not yet collected (Phase 3 backup step); not a pass',
    },
}
(report / 'test-report.json').write_text(
    json.dumps(payload, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

lines = ['# Test report', '',
         '| check | layer | state |', '|---|---|---|']
for c in checks:
    lines.append(f"| {c['name']} | {c['layer']} | {c['state']} |")
lines += ['',
          f"{payload['summary']['passed']} passed, {len(skipped)} skipped, {len(failed)} failed.",
          '',
          'SKIP = device baseline not yet collected (Phase 3 backup step).',
          'A skipped check is NOT a pass; it blocks release just like a failure.',
          '',
          'L4 real-device verification is not part of CI.',
          'A release additionally requires a PASS record in verification/device/.',
          '']
(report / 'test-report.md').write_text('\n'.join(lines), encoding='utf-8')

if failed:
    print(f"{len(failed)} check(s) failed", file=sys.stderr)
    sys.exit(1)
print(f"{payload['summary']['passed']} passed, {len(skipped)} skipped, 0 failed")
PY