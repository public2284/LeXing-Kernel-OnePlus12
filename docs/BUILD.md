# Build system

The kernel is compiled in GitHub Actions, never locally. The local machine
develops, reviews, configures, triggers and inspects (Chapter 13.1).

## Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `kernel-test` | pull request, manual | Static checks only: workflow pinning, shellcheck, manifest/registry schema, patch SHA256, Kconfig symbol existence, AnyKernel3 config |
| `toolchain-image` | manual only | Builds and publishes the pinned builder image to GHCR; writes out the digest for manual write-back |
| `kernel-build` | manual only | Phase-gated compile, packaging, full verification, metrics |
| `experimental-build` | manual, `experimental/*` branches | Same pipeline with `-experimental` artifacts, 7-day retention, no write permissions |
| `release-build` | manual, strict `v*` tags | Candidate build, L4 gate, then publish behind the `production` environment |

## Verification layers

CI never claims device compatibility. Checks are layered and labeled in the test
report:

- **L1-format** — packaging and tooling structure (mkbootimg round trip,
  flashable zip layout, SHA256). Passing means the image was built and packed
  correctly, nothing more.
- **L2-static** — static comparison against the Phase 0 device baseline: kernel
  release string, boot parameters, Kconfig diff, KMI symbol list, vendor module
  symbol dependencies, module vermagic.
- **L3-static** — DTB/DTBO structural comparison against the device's extracted
  blobs.
- **L4** — real device boot, per Chapter 9's matrix. Not CI. The release gate
  requires a `PASS` record in `verification/device/`; `FAIL` and missing records
  both block publication.

## Artifacts (rule 13.6)

Every build produces: kernel image and modules, AnyKernel3 zip, final `.config`
with defconfig diff, full build log, `SHA256SUMS`, `build-info.json` (source
commits, submodule pins, patch list, toolchain, image digest, environment
version), `test-report.json/md`, `metrics.json`. Nothing compiled is committed
to the repository.

## Resource accounting (rule 13.5)

`build/metrics.sh` samples memory, disk, per-step timings, cache hits and
artifact sizes every build; the report job renders them into the run summary.
Escalation rules: only if builds consistently exceed 60 minutes or exceed 80%
of runner disk do we evaluate larger runners — which for a personal GitHub
account are unavailable (GitHub-hosted larger runners require a Team or
Enterprise organization). Fallback options: a Team-plan organization or a
self-hosted Actions runner. Checks are never dropped to save resources.

## Cost baseline (public repository)

- Standard GitHub-hosted runners: free, unlimited minutes
- Actions artifacts: 500 MB (GitHub Free), shared with Packages storage
- Actions cache: 10 GB per repository
- GHCR container images: currently free (public packages)
- Environment required reviewers: available on public repositories
