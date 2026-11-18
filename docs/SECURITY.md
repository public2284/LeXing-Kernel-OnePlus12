# Build security

- **Pinned inputs.** Submodules are pinned to commits; actions are pinned to
  commit SHAs; the builder image is pinned by digest; toolchain artifacts are
  verified by SHA256. Nothing floats on a moving ref (rule 13.4.1–3).
- **Least privilege.** Every workflow declares its permissions; PR checks are
  read-only and never use `pull_request_target`. Only the release publish job
  holds `contents`/`id-token`/`attestations` write.
- **No auto-pull of upstream change.** Dependabot is limited to GitHub Actions
  versions and always behind a human merge decision (rule 13.4.2).
- **No secrets in the repository.** No signing keys or tokens are committed;
  `.gitignore` blocks the usual suspects.
- **No fake success.** A failed check fails the run; releases happen only after
  build success, L4 PASS, and human approval (rule 13.4.10).
- **Provenance.** Builds record source commits, patch list, toolchain and
  environment version in `out/build-info.json`; releases carry SHA256SUMS and a
  build-provenance attestation.
