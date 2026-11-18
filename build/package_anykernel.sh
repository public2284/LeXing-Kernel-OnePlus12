#!/usr/bin/env bash
# Package the built kernel into an AnyKernel3 flashable zip.
#
# Environment: SUFFIX (e.g. -experimental, -candidate).
# Reads out/ and writes dist/ containing the zip, SHA256SUMS, RELEASE_NOTES.md
# and a copy of build-info.json.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

SUFFIX="${SUFFIX:-}"
out="$ROOT/out"
dist="$ROOT/dist"
ak3="$ROOT/AnyKernel3"

[[ -d "$out" ]] || die "no out/ directory — run build_kernel.sh first"
[[ -d "$ak3" ]] || [[ -d "$ak3/.git" ]] || die "AnyKernel3 submodule not configured yet (Phase 2 task)"

version="$(awk -F'=' '/^KERNEL_RELEASE=/{print $2}' "$out/build-info.json" 2>/dev/null | tr -d '"' || true)"
[[ -n "$version" ]] || version="unreleased"
zip_name="LeXingKernel-$version$SUFFIX.zip"

step "Stage AnyKernel3 payload"
# Phase 2/3 implementation: copy Image, modules and dtb into the AnyKernel3
# tree, fill AnyKernel3/config (device, kernel string, block paths) from
# configs/, then zip -r "$dist/$zip_name" .
die "packaging is implemented in Phase 2/3 together with AnyKernel3/config"

step "Write manifest and notes"
# dist/SHA256SUMS covers every file in dist/ (computed after zipping plus the
# zip itself), dist/RELEASE_NOTES.md is generated from build-info.json.
die "manifest generation is implemented in Phase 2/3"
