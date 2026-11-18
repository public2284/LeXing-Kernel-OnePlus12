# Patches

Every modification to third-party source lands as a file in `patches/` with a
complete `patches/PATCHES.manifest` entry: id, name, source URL, upstream
commit, SHA256, feature id, target, license.

Import procedure:

1. Import the patch from its official source into `patches/NNNN-name.patch`.
2. Add the manifest entry with the imported file's SHA256.
3. `build/checks/patch_integrity.sh` passes locally.
4. Open a pull request; kernel-test runs the integrity and schema checks.
5. Once the kernel submodule exists, the PR also proves the patch series still
   applies cleanly to the pinned kernel commit (`git apply --check`).

Hard rules:

- No unrecorded patch. No silent overwrite: editing a patch means a new entry
  and a review.
- Patches from different projects are never mixed inside one file.
- Patches are applied in manifest order; conflicts abort the whole build rather
  than leaving a half-patched tree.
