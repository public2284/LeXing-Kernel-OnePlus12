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
  [[ -f "$metrics_json" ]] || die "no $metrics_json to render"
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
