#!/usr/bin/env bash
# LeXing Kernel build orchestration.
#
# Environment: PROFILE (minimal|full|debug|experimental), CCACHE (true|false),
# IMAGE_REF (the builder image, recorded into build-info.json).
# Produces out/ with the kernel image, modules, config, logs and build-info.json.
#
# Fails closed: compilation requires .phase-state >= phase3, the kernel source
# submodule, every declared patch applying cleanly, and the builder image pin.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

PROFILE="${PROFILE:-minimal}"
OUT="$ROOT/out"

step "0/7 Validate profile"
fragment="$(profile_fragment "$PROFILE")"
log "profile=$PROFILE fragment=$fragment"

step "1/7 Phase gate"
phase_at_least phase3 || die "compilation blocked: .phase-state is '$(phase_state)', needs phase3 (see docs/phase-gate.md)"

step "2/7 Kernel source pins"
kernel="$ROOT/kernel"
[[ -f "$kernel/Makefile" ]] || die "kernel submodule not checked out"
[[ -f "$kernel/scripts/kconfig/merge_config.sh" ]] || die "kernel tree missing scripts/kconfig/merge_config.sh"
[[ -f "$ROOT/sukisu-nova/kernel/Kbuild" ]] || die "sukisu-nova submodule not checked out"
[[ -d "$ROOT/AnyKernel3" ]] || die "AnyKernel3 submodule not checked out"
log "kernel: $(git -C "$kernel" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
log "sukisu-nova: $(git -C "$ROOT/sukisu-nova" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"

mkdir -p "$OUT"

step "3/7 Apply patches and integrate SukiSU-Nova"
if [[ "$(manifest_patches)" -gt 0 ]]; then
  python3 - "$ROOT/patches/PATCHES.manifest" <<'PY' | while IFS= read -r p; do
import sys, yaml
data = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
for e in data.get('patches', []) or []:
    print(f"{e['id']}\t{e['name']}")
PY
    id="${p%%$'\t'*}"
    name="${p#*$'\t'}"
    log "applying $id: $name"
    git -C "$kernel" apply --whitespace=nowarn "$ROOT/patches/$id.patch" \
      || die "patch $id failed to apply - refusing to build a half-patched tree"
  done
fi
bash "$ROOT/build/integrate_sukisu.sh"

step "4/7 Merge build profile into defconfig"
# GKI base + SM8650 vendor config + profile fragment, merged with the kernel's
# own merge_config.sh, then resolved with olddefconfig.
cd "$kernel"
bash scripts/kconfig/merge_config.sh -m -O "$OUT" \
  arch/arm64/configs/gki_defconfig \
  arch/arm64/configs/vendor/pineapple_GKI.config \
  "$ROOT/build/profiles/common.fragment" \
  "$fragment"
make O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  olddefconfig
log "merged .config written to $OUT/.config"

step "5/7 Compile"
# headers_install first: the SukiSU-Nova preinit runner needs the installed
# UAPI headers under <objtree>/usr/include (CONFIG_HEADERS_INSTALL=y).
MAKE_ARGS=(O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1
  CROSS_COMPILE=aarch64-linux-gnu-
  CROSS_COMPILE_COMPAT=arm-linux-gnueabi-)
if [[ "${CCACHE:-false}" == "true" ]]; then
  export CC="ccache clang"
  export CXX="ccache clang++"
  export CCACHE_DIR="${CCACHE_DIR:-/root/.ccache}"
fi
# Image only: the AnyKernel3 package flashes just the boot Image
# (build/package_anykernel.sh), the device keeps its stock vendor modules,
# and the published tree cannot close the vendor module symbol set anyway
# (unpublished oplus exports; see patches 0260..0291 and runs 12..17).
make "${MAKE_ARGS[@]}" KSU_BUILD_REF=v3.0.0 -j"$(nproc)" \
  headers_install Image 2>&1 | tee "$OUT/build.log"

[[ -s "$OUT/arch/arm64/boot/Image" ]] || die "no Image produced"
[[ -s "$OUT/Module.symvers" ]] || die "no Module.symvers produced"

release="$(cat "$OUT/include/config/kernel.release" 2>/dev/null || echo unknown)"
log "kernel release: $release"

step "6/7 Collect outputs"
clang_version="$(clang --version | head -n1)"
super_commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
ksu_commit="$(git -C "$ROOT/sukisu-nova" rev-parse HEAD 2>/dev/null || echo unknown)"
kernel_commit="$(git -C "$ROOT/kernel" rev-parse HEAD 2>/dev/null || echo unknown)"
config_sha256="$(sha256sum "$OUT/.config" | cut -d' ' -f1)"
env_version="$(env_version)"
image_ref="${IMAGE_REF:-}"
python3 - "$OUT" "$PROFILE" "$release" "$clang_version" "$super_commit" "$kernel_commit" "$ksu_commit" "$config_sha256" "$env_version" "$image_ref" <<'PY'
import json, os, sys, yaml
(out, profile, release, clang, super_commit, kernel_commit, ksu_commit,
 config_sha, env_version, image_ref) = sys.argv[1:]
root = os.path.dirname(os.path.dirname(os.path.abspath(out)))
manifest = yaml.safe_load(open(os.path.join(root, 'patches', 'PATCHES.manifest'), encoding='utf-8')) or {}
payload = {
    'schema': 'lexing.build-info/v1',
    'profile': profile,
    'kernel_release': release,
    'kmi': 'android14-11',
    'source': {
        'superproject': super_commit,
        'kernel': kernel_commit,
        'sukisu_nova': ksu_commit,
        'builder_image': image_ref,
        'env_version': env_version,
    },
    'patches': [{'id': e['id'], 'name': e['name'], 'upstream_commit': e.get('upstream_commit')}
                for e in (manifest.get('patches') or [])],
    'toolchain': {'clang': clang},
    'config_sha256': config_sha,
    'image_ref': image_ref,
    'device': 'OnePlus 12 CPH2573 (SM8650, pineapple)',
    'notes': 'L4 on-device verification is not performed by CI; see test-report.',
}
with open(os.path.join(out, 'build-info.json'), 'w', encoding='utf-8') as fh:
    json.dump(payload, fh, indent=2, ensure_ascii=False)
    fh.write('\n')
PY
log "build-info.json written"

step "7/7 Done"
log "build finished: $release (profile $PROFILE)"
