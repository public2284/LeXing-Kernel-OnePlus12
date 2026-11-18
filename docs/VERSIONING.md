# Versioning: two independent version chains

The project tracks two version numbers that never have to move together.

| Chain | Manages | Tags |
|---|---|---|
| Kernel Release | kernel source submodule, patches, SukiSU, SUSFS, Feature Registry | `vX.Y.Z` |
| Build Environment Release | Ubuntu base image (digest), Clang, Python, build deps, Docker image digest | `env-bN` |

`build/docker/ENV_VERSION` holds the current environment version (b0…). Every
build records it in `out/build-info.json`, so any kernel release names the
environment that built and tested it.

Why it matters (Chapter 13 design intent):

- Upgrading SUSFS touches only the kernel chain; Clang stays put.
- Upgrading Clang or the base image touches only the environment chain; patches
  stay put.
- An environment change still requires a full rebuild plus complete L1–L3
  verification before any release uses it — independence is not an exemption
  from retesting.

The builder image is published as `ghcr.io/<owner>/lexing-kernel-builder`,
tagged with the environment version; `build/docker/image.lock` pins the exact
digest the kernel build must use.
