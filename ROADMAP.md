# Roadmap

Linux Recovery Toolkit is developed as a cautious, observable and testable set of tools for Linux recovery. No script should claim that a system is safe to reinstall based on incomplete evidence.

## Current baseline

- v0.1: read-only audit and SMART reporting
- v0.2: dry-run-first HOME backup and checksum comparison
- v0.3: package/service inventories and reinstall preflight

## v0.4 - Backup safety and reliability

- Distinguish portable data copies from Linux metadata-preserving recovery.
- Detect the destination filesystem and communicate compatibility limits before copying.
- Fail closed when reinstall preflight cannot prove that the source and backup live on separate physical disks.
- Capture and interpret SMART tool failures and status bits correctly.
- Treat output directories with private permissions.
- Introduce non-privileged functional tests with mocks for block devices and tools.

Tracking: [backup profiles](https://github.com/tidus747/linux-recovery-toolkit/issues/7), [preflight safety](https://github.com/tidus747/linux-recovery-toolkit/issues/8), [SMART reporting](https://github.com/tidus747/linux-recovery-toolkit/issues/9), [functional CI](https://github.com/tidus747/linux-recovery-toolkit/issues/10).

## v0.5 - Selective recovery

- Classify persistent data, optional configuration and rebuildable state.
- Document and test encrypted HOME workflows and multi-user recovery.
- Introduce optional profiles without encoding a particular machine's usernames or paths.
- Make inventory reports usable across distributions, while clearly identifying unsupported platforms.

## v0.6 - Restore and rebuild

- Provide guarded, dry-run-first restore workflows with explicit source/destination checks.
- Check archive integrity and metadata restoration where the format supports it.
- Verify mounts, critical systemd services, networking and user data after reinstall.
- Do not automatically re-enable old units or install old packages without review.

## v1.0 - Stable release

- Document compatibility matrix and required privileges for every command.
- Stabilize CLI, output and exit-code contracts.
- Run acceptance tests and publish audited, reproducible installation instructions.
- Publish an operator handbook and clear recovery/rollback procedures.

## Documentation website

The website is a parallel project, not a runtime dependency of the toolkit.

- Landing page built from the [Astro Distro](https://github.com/ansango/astro-distro) theme.
- Published at https://tidus747.github.io/linux-recovery-toolkit/ after GitHub Pages activation.
- Guides and tool reference for all public commands.
- Version-specific cautions, tested compatibility and security principles.
- GitHub Actions build and deployment.
- Preserve Astro Distro's upstream MIT copyright notice when adapting its assets or source.

Tracking: [website](https://github.com/tidus747/linux-recovery-toolkit/issues/5), [documentation reference](https://github.com/tidus747/linux-recovery-toolkit/issues/6).

## Contribution rules

- Small, reviewable branches and pull requests targeting `main`.
- No destructive operations or assumptions about a user's distribution without checking.
- ShellCheck and Bash syntax validation are the minimum; functional tests are required for safety-relevant changes.
- Documentation and examples must match the script version they describe.
- Never commit backups, private reports, user credentials, disk serials or machine-specific recovery data.
