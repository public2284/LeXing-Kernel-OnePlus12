# configs/

Device-specific configuration, all of it produced by Phase 0 (read-only device
investigation) and Phase 1 (technical plan):

- `device/` — device facts: model, SoC, kernel release string, boot cmdline,
  boot/init_boot/vendor_boot header versions and parameters.
- `device/dtb/` — extracted original DTB/DTBO blobs, the L3 comparison baseline.
- `kmi/` — exported-symbol list and vendor_dlkm module dependencies extracted
  from the device, the L2 KMI baseline.
- `device.defconfig` — the device's defconfig fragment once Phase 0/1 settle it.

Everything here is evidence, not guesswork: no file is filled in until the
corresponding device data has actually been read and recorded.
