# verification/device/ — L4 records

One Markdown file per release tag: `vX.Y.Z.md`. The release-build workflow's
verify-gate reads the record and lets a release proceed only when its status is
PASS. CI checks can never substitute for it.

Template:

    # Device verification — vX.Y.Z

    status: PASS
    device: OnePlus 12 CPH2573
    kernel_release: 6.1.x
    tester: <name>
    date: YYYY-MM-DD
    build: <commit or run the flashable zip came from>

    ## Chapter 9 test matrix
    | item | result | notes |
    |---|---|---|
    | cold boot | PASS | ... |
    | reboot x5 | PASS | ... |
    | recovery boot | PASS | ... |
    | Wi-Fi / Bluetooth / NFC | PASS | ... |
    | mobile data / calls | PASS | ... |
    | fingerprint | PASS | ... |
    | charging / USB | PASS | ... |
    | suspend / resume | PASS | ... |
    | SukiSU manager + module install/remove | PASS | ... |
    | SUSFS functions | PASS | ... |
    | cameras, all lenses, 4K120, 1080P120, LUT | PASS | ... |
    | battery readings / temperatures | PASS | ... |

    Rollback used in case of failure: <which slot / backup image>

States and their consequences:

- `PASS` — every matrix item passed; release proceeds.
- `FAIL` — any item failed; the release stays blocked. Record also what was
  observed and which backup restored the device.
- Missing or malformed — treated as `NEEDS_DEVICE_VERIFICATION`; blocked.
- Records are committed through normal pull requests with the tester named.
