# SMART health inspection (v0.4)

The `smart-health.sh` helper reports a limited, privacy-conscious overview of physical disks. It does not start self-tests or change SMART settings.

## Usage

```bash
bash ./scripts/smart-health.sh
bash ./scripts/smart-health.sh /dev/sdX
bash ./scripts/smart-health.sh --device-type sat /dev/sdX
```

An explicit `--device-type` sends `-d TYPE` to smartctl for USB/SATA, NVMe bridges or RAID. Confirm the correct type for the **actual** adapter in your installed smartctl man page; do not guess and never automate potentially unsafe controller-specific options.

## Dependencies and permissions

- Bash, smartctl (smartmontools), lsblk, awk and grep.
- Run as a regular user with sudo available, or as root from an intentionally privileged session.
- The command may request sudo to query SMART, but does not format, mount, repartition, or initiate a self-test.
- To reduce accidental disclosures, smartctl is invoked using `-q noserial` and only selected health lines are printed. Device paths and models remain identifying information.

## Result contract

| Exit | Result | Meaning |
| --- | --- | --- |
| 0 | PASS | Recognizable SMART health status with no error/warning bits from this query |
| 1 | WARN | SMART reports a failing state, threshold/historical warning or logged errors |
| 2 | UNKNOWN | Data unavailable, command failed, missing device, permission denied or incomplete evidence |

The smartctl exit status is a bitmask, **not** a single ordinary success/failure code. Bits 0–2 indicate parsing, device access or SMART command failures. Bits 3–7 indicate reported device health/history issues. When both groups occur, WARN takes priority in the command's exit status and the per-device message also identifies incomplete evidence.

A PASS indicates **no reported failure from the selected query**, not a guarantee that the drive is reliable. No SMART support, USB bridge limitations or no recognizable health line must never become a PASS.

## Troubleshooting

If a USB enclosure does not expose SMART, inspect `lsblk -o NAME,TYPE,TRAN,MODEL` and the documentation for the actual bridge. Check the installed `man smartctl` before choosing a `--device-type`. Do not try controller-specific modes indiscriminately.

## Verification and rollback

Run `bash tests/smart-health.sh` (uses mocks only) and `bash -n scripts/smart-health.sh`. A functional smoke test on real devices requires manual selection and inspection.

To roll back this code change, revert the corresponding PR commit; this helper does not modify disk state. The change **does** update its exit-status contract: callers must distinguish WARN (1) and UNKNOWN (2).

Reference: https://manpages.debian.org/testing/smartmontools/smartctl.8.en.html
