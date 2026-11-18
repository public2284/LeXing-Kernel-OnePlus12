#!/usr/bin/env bash
# Schema check for patches/PATCHES.manifest and the Feature Registry records.
# Real check, runs on PRs.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

python3 - "$ROOT" <<'PY'
import pathlib, sys
import yaml

root = pathlib.Path(sys.argv[1])
failures = []

manifest = root / 'patches' / 'PATCHES.manifest'
if not manifest.exists():
    failures.append('missing patches/PATCHES.manifest')
else:
    try:
        data = yaml.safe_load(manifest.read_text(encoding='utf-8')) or {}
    except yaml.YAMLError as e:
        failures.append(f'PATCHES.manifest is not valid YAML: {e}')
        data = {}
    patches = data.get('patches', []) or []
    if not isinstance(patches, list):
        failures.append("PATCHES.manifest: 'patches' must be a list")
        patches = []
    required = ['id', 'name', 'source_url', 'upstream_commit', 'sha256', 'license']
    for i, entry in enumerate(patches):
        if not isinstance(entry, dict):
            failures.append(f'patch entry {i} must be a mapping')
            continue
        for key in required:
            if not entry.get(key):
                failures.append(f'patch entry {i} ({entry.get("id", "?")}): missing {key}')
        pid = entry.get('id', '')
        if pid and not pid.startswith(('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')):
            failures.append(f"patch id '{pid}' should be numbered (sort order matters)")

    declared = {entry.get('id') for entry in patches if isinstance(entry, dict)}
    on_disk = {p.name for p in (root / 'patches').glob('*.patch')}
    if declared & on_disk != on_disk or on_disk & declared != declared:
        extra = on_disk - declared
        missing = declared - on_disk
        if extra:
            failures.append(f'patch files without manifest entry: {sorted(extra)}')
        if missing:
            failures.append(f'manifest entries without patch file: {sorted(missing)}')
        if extra or missing:
            pass

if not (root / 'features').is_dir():
    failures.append('missing features/ directory')
else:
    required_feature = [
        'id', 'name', 'description', 'source', 'type', 'default_state',
        'risk', 'enable', 'disable', 'rollback',
    ]
    for f in sorted((root / 'features').rglob('*.yaml')):
        try:
            entry = yaml.safe_load(f.read_text(encoding='utf-8')) or {}
        except yaml.YAMLError as e:
            failures.append(f'{f.relative_to(root)}: invalid YAML: {e}')
            continue
        for key in required_feature:
            if not entry.get(key):
                failures.append(f'{f.relative_to(root)}: missing {key}')
        if entry.get('type') not in (None, 'compile-time', 'runtime', 'hybrid'):
            failures.append(f"{f.relative_to(root)}: bad type {entry.get('type')!r}")

if failures:
    print('FAIL manifest/registry schema:', file=sys.stderr)
    for line in failures:
        print(f'  - {line}', file=sys.stderr)
    sys.exit(1)
print(f'[lexing] manifest schema OK: 0 feature records, manifest entries consistent '
      f'(placeholder count printed in Phase 1)')
PY
