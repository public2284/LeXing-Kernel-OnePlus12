#!/usr/bin/env bash
# Workflow hygiene: every referenced action must be pinned to a 40-char commit
# SHA (with the version in a trailing comment), and pull_request_target is
# forbidden anywhere (project rule 13.4, least privilege). Real check, runs on PRs.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

wf="$ROOT/.github/workflows"
[[ -d "$wf" ]] || die "missing $wf"

status=0

while IFS= read -r ref; do
  # ref looks like: <file>:<line>:        uses: actions/checkout@<sha> # vX.Y.Z
  file="${ref%%:*}"
  rest="${ref#*:}"
  line_no="${rest%%:*}"
  uses="${rest#*:}"
  uses="$(echo "$uses" | sed -E 's/^\s*-?\s*uses:\s*//; s/\s*#.*$//')"
  case "$uses" in
    ./.github/workflows/*) continue ;;   # local reusable workflows are fine
    @*[!0-9a-f]*) ;;
    *)
      if [[ "$uses" != *@[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]* ]]; then
        echo "FAIL $file:$line_no: '$uses' is not pinned to a commit SHA"
        status=1
      fi
      ;;
  esac
done < <(grep -rnE '^\s*-?\s*uses:' "$wf" | grep -v '^Binary')

# Match the event trigger key only (pull_request_target:), never the words in
# a step name such as this check's own label.
if grep -rnE 'pull_request_target\s*:' "$wf"; then
  echo "FAIL pull_request_target is forbidden in $wf"
  status=1
fi

# YAML syntax: a step name containing ': ' silently breaks the whole workflow.
python3 - "$wf" <<'PY'
import sys, pathlib, yaml
for f in sorted(pathlib.Path(sys.argv[1]).glob('*.yml')):
    try:
        yaml.safe_load(f.read_text(encoding='utf-8'))
    except yaml.YAMLError as e:
        sys.exit(f'FAIL {f.name}: {e}')
PY
if [[ "$status" -eq 0 ]]; then
  log "workflow hygiene OK: all actions SHA-pinned, no pull_request_target"
else
  die "workflow hygiene failed"
fi
