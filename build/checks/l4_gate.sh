#!/usr/bin/env bash
# L4 gate: the on-device verification record for a release tag.
#
#   l4_gate.sh <tag>  — prints PASS / FAIL / NEEDS_DEVICE_VERIFICATION
#
# The record lives at verification/device/<tag>.md and is committed by the
# tester through a normal pull request. State machine (hard rule):
#   PASS                      all required on-device tests passed — release allowed
#   FAIL                      at least one test failed — release blocked
#   missing/incomplete        NEEDS_DEVICE_VERIFICATION — release blocked
#
# CI being green never satisfies this gate; the publish job additionally
# requires its output to be PASS.
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

tag="${1:?usage: l4_gate.sh <tag>}"
record="$(device_record "$tag")"

if [[ ! -f "$record" ]]; then
  echo "NEEDS_DEVICE_VERIFICATION"
  echo "no record at verification/device/$tag.md" >&2
  exit 0
fi

state="$(grep -E '^status:' "$record" | head -n1 | sed -E 's/^status:\s*//; s/\s*$//')"

case "$state" in
  PASS|FAIL)
    echo "$state"
    ;;
  *)
    echo "NEEDS_DEVICE_VERIFICATION"
    echo "record $tag.md has no valid 'status:' line (expected PASS or FAIL)" >&2
    ;;
esac
