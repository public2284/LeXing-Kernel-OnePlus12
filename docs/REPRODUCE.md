# Reproducing a build

Prerequisites: a repository checkout with submodules.

    git clone --recurse-submodules <repo>
    cd LeXing-Kernel-OnePlus12

Everything that defines the build is in the checkout:

- `build/docker/image.lock` — exact builder image digest
- `build/docker/toolchain.env` — toolchain pins, verified against
  `build/docker/checksums.sha256`
- `.gitmodules` — every submodule pinned to a commit
- `patches/PATCHES.manifest` — every patch with its SHA256
- `build/profiles/` — the build profile fragments

A build is reproduced by dispatching the Kernel Build workflow on the same
commit with the same profile, or locally by running the same scripts inside the
pinned builder image. `out/build-info.json` records every input listed above;
two builds with identical build-info are expected to produce identical
artifacts, verified through `dist/SHA256SUMS`.

No step in this document requires a local kernel toolchain — that is the point
of the cloud build system (Chapter 13.1).
