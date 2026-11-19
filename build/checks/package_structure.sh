#!/usr/bin/env bash
# L1-format: the dist/ directory carries every required deliverable with a
# schema-valid build-info.json (rule 13.6).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

dist="$ROOT/dist"
[[ -d "$dist" ]] || die "missing dist/"

status=0
for f in SHA256SUMS RELEASE_NOTES.md build-info.json; do
  [[ -f "$dist/$f" ]] || { echo "FAIL dist/ missing $f"; status=1; }
done
count=$(find "$dist" -maxdepth 1 -name '*.zip' | wc -l)
[[ $count -eq 1 ]] || { echo "FAIL dist/ expected 1 zip, found $count"; status=1; }

python3 - "$dist/build-info.json" <<'PY' || { echo 'FAIL build-info.json is not schema-valid' >&2; exit 1; }
import json, sys
info = json.load(open(sys.argv[1], encoding='utf-8'))
required = ['schema', 'profile', 'kernel_release', 'kmi', 'source', 'patches', 'toolchain', 'config_sha256']
missing = [k for k in required if k not in info or info[k] in (None, '')]
if missing:
    sys.exit(f'missing keys: {missing}')
src_required = ['superproject', 'kernel', 'sukisu_nova', 'builder_image', 'env_version']
missing = [k for k in src_required if k not in info['source'] or info['source'][k] in (None, '')]
if missing:
    sys.exit(f'missing source keys: {missing}')
print(f"build-info OK: {info['profile']} {info['kernel_release']} env={info['source']['env_version']}")
PY

[[ $status -eq 0 ]] || die "package structure failed"
log "package structure OK"