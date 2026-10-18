# Graphics and GPU audit

This is a read-only diagnostic. It does not modify drivers, modules, installed packages, boot settings or system configuration.

## Run

    bash ./scripts/audit-gpu.sh

    bash ./scripts/audit-gpu.sh --help

## Evidence

- OS, running kernel and graphical session.
- GPU models and bound drivers from lspci -nnk, without PCI addresses or numeric IDs.
- Loaded graphics modules, if lsmod is available.
- DRM connector counts and statuses from /sys/class/drm.
- Counts of selected nouveau FIFO/PGRAPH, i915 GPU HANG, amdgpu, NVIDIA and firmware loading errors from current-boot journalctl; fall back to dmesg.
- X11 provider count only when an X11 session and xrandr are available.

The script never prints raw kernel log lines. A private temporary log file is removed on exit; device models and kernel version may still need redaction before sharing.

## Exit codes

| Code | Result | Meaning |
| --- | --- | --- |
| 0 | PASS | Readable PCI, connector and kernel-log evidence; no matching warning signature |
| 1 | WARN | A selected graphics or GPU firmware error signature was found |
| 2 | UNKNOWN | Critical information was missing or inaccessible, without warning evidence |

WARN takes precedence over UNKNOWN. These are diagnostic *heuristics*, not proof of a hardware defect or its root cause. PASS does not guarantee graphics are working. A missing journal is UNKNOWN, not PASS.

## Requirements

Bash, lspci (pciutils), awk. Optional: lsmod, journalctl, dmesg, xrandr (X11 only) and DRM sysfs. Tested through mocked Intel i915 and NVIDIA nouveau cases; real distributions, GPU generations and permissions require field validation.

## Troubleshooting and privacy

Review locally with lspci -nnk, lsmod and journalctl -k -b --no-pager; consult the installed man pages. Do not paste unredacted raw journal output publicly. This tool does not assert that disabling nouveau, changing kernel parameters or installing a proprietary driver is safe.

## Test and rollback

    bash tests/audit-gpu.sh
    bash -n scripts/audit-gpu.sh

This code does not change system configuration. Rollback is reverting the introducing PR; the script creates only a private temporary file, removed when it exits.
