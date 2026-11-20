#!/usr/bin/env bash
# Build resource metrics (project rule 13.5).
#
#   metrics.sh sample <step>   — record a sample for a build step (called from
#                                build_kernel.sh in Phase 2/3)
#   metrics.sh --render        — render out/metrics.json into the Job Summary
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

out="$ROOT/out"
metrics_json="$out/metrics.json"

meminfo_total_kb() { awk '/^MemTotal:/{print $2}' /proc/meminfo; }
meminfo_avail_kb() { awk '/^MemAvailable:/{print $2}' /proc/meminfo; }
disk_free_mb() { df -BM --output=avail "${1:-$ROOT}" | tail -n1 | tr -dc '0-9'; }

sample() {
  local label="$1" now
  now="$(date -u +%s)"
  mkdir -p "$out"
  printf '%s\t%s\tmem_total_kb=%s\tmem_avail_kb=%s\tdisk_free_mb=%s\n' \
    "$now" "$label" "$(meminfo_total_kb)" "$(meminfo_avail_kb)" "$(disk_free_mb)" \
    >> "$out/metrics.tsv"
  log "metrics sample: $label"
}

render() {
  # summarize the samples collected by build_kernel.sh (out/metrics.tsv) into
  # out/metrics.json; render that. The metrics.json file may also be produced
  # by other tooling, in which case it is simply displayed as-is.
  if [[ ! -f "$metrics_json" && -f "$out/metrics.tsv" ]]; then
    python3 - "$out/metrics.tsv" "$metrics_json" <<'PY'
import json, sys
tsv, out = sys.argv[1], sys.argv[2]
rows = []
for line in open(tsv, encoding='utf-8', errors='replace'):
    parts = line.rstrip('\n').split('\t')
    if len(parts) < 2 or not parts[0]:
        continue
    row = {'unix_utc': parts[0], 'step': parts[1]}
    for kv in parts[2:]:
        if '=' in kv:
            k, v = kv.split('=', 1)
            row[k] = v
    rows.append(row)
with open(out, 'w', encoding='utf-8') as fh:
    json.dump(rows, fh, indent=2)
    fh.write('\n')
PY
  fi
  if [[ ! -f "$metrics_json" ]]; then
    echo "no $metrics_json to render (no metrics.tsv was collected either - the build job may not run build_kernel.sh)" >&2
    exit 0   # report the gap honestly; the report job stays green
  fi
  {
    echo '## Build metrics'
    echo '```json'
    cat "$metrics_json"
    echo '```'
  } >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
}

case "${1:-}" in
  sample) sample "${2:-step}" ;;
  --render) render ;;
  *) die "usage: metrics.sh sample <step> | metrics.sh --render" ;;
esac
