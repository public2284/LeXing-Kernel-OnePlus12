# LeXing Kernel — OnePlus 12 Edition

Custom GKI 2.0 kernel for the OnePlus 12 (CPH2573): migration from KernelSU 4.1.3
with built-in SUSFS 2.2.0 to SukiSU Ultra, plus a modular, well-gated feature
system.

This is a daily-driver device. **Boot stability and recoverability outrank
features, benchmarks and new technology.** Nothing is flashed, rebooted,
cleaned or reconfigured on the phone without explicit, risk-stated approval.

## Status

`PHASE=phase0` — read-only device and source investigation
([.phase-state](.phase-state)). Build workflows exist in this repository but are
blocked until Phase 3 is approved. See [docs/phase-gate.md](docs/phase-gate.md).

## Build system

GitHub hosts the code, GitHub Actions builds it. The local machine only develops,
reviews, configures and triggers — no local kernel compilation is required or
supported.

| Workflow | Trigger | Purpose |
|---|---|---|
| [kernel-test](.github/workflows/kernel-test.yml) | pull request, manual | Static, no-compile checks |
| [kernel-build](.github/workflows/kernel-build.yml) | manual only | Compile, package, verify (phase-gated) |
| [experimental-build](.github/workflows/experimental-build.yml) | manual, `experimental/*` branches | Isolated experiments, 7-day artifacts |
| [toolchain-image](.github/workflows/toolchain-image.yml) | manual only | Build and publish the pinned builder image to GHCR |
| [release-build](.github/workflows/release-build.yml) | manual, strict `v*` tags, approval | Candidate build, L4 gate, then publish |

Docs: [BUILD.md](docs/BUILD.md) — [VERSIONING.md](docs/VERSIONING.md) —
[PATCHES.md](docs/PATCHES.md) — [REPRODUCE.md](docs/REPRODUCE.md) —
[SECURITY.md](docs/SECURITY.md).

## Layout

    build/             build orchestration, profiles, checks, builder image spec
    patches/           imported patches + PATCHES.manifest (every source recorded)
    configs/           device defconfig fragments, KMI and symbol baselines
    features/          Feature Registry (compile-time vs runtime, deps, risks)
    verification/device/  on-device test records (L4 release gate)
    docs/              everything above

## Release gate in one sentence

A release needs: all CI checks green on a strict `vX.Y.Z` tag **and** an
on-device verification record with `status: PASS` in
[verification/device/](verification/device/). CI green alone never ships.
