#!/usr/bin/env bash
# Release tag gate: a release may only be built from a strict semver tag that
# has no release yet. Runs before any candidate build (rule 13.3: only reviewed
# stable versions enter the release flow; nothing is ever overwritten).
set -euo pipefail

source "$(cd "$(dirname "$0")/../" && pwd)/common.sh"

tag="${GITHUB_REF_NAME:-}"

if [[ "$GITHUB_REF" != refs/tags/* ]]; then
  die "refused: release-build runs on tags only, got '$GITHUB_REF'"
fi

if ! [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "refused: tag '$tag' is not strict semver vX.Y.Z (no suffixes, no rc/pre-releases — those stay candidates)"
fi

if command -v gh >/dev/null 2>&1 && [[ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]]; then
  if gh api "repos/$GITHUB_REPOSITORY/releases/tags/$tag" --silent 2>/dev/null; then
    die "refused: a release for $tag already exists — releases are never overwritten; cut a new tag instead"
  fi
  log "no existing release for $tag"
else
  log "gh or token unavailable: existing-release check skipped (relying on tag protection rules)"
fi

log "release tag OK: $tag"
