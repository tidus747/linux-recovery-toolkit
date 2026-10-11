# Linux Recovery Toolkit

A conservative toolkit for auditing, backing up and rebuilding Linux systems without carrying years of hidden state from one installation to the next.

The project follows one rule above all others:

> Observe first. Change later.

## Goals

- Audit a Linux system before reinstalling it.
- Separate personal data from application state, caches and legacy configuration.
- Check storage health before trusting a disk during a migration.
- Build verifiable backups before destructive operations.
- Make future Linux reinstalls reproducible.
- Keep machine-specific and personal information out of the repository.

## Current status

### v0.1 - Audit & inventory

The first milestone is intentionally read-only:

- `audit-system.sh` - distribution, kernel, systemd, desktop and basic hardware.
- `audit-storage.sh` - disks, filesystems, mounts and space usage.
- `audit-home.sh` - top-level HOME usage, including hidden directories.
- `smart-health.sh` - focused SMART health information without disk serial numbers.
- `audit-all.sh` - collect the above reports into a local timestamped directory.

Planned later milestones will add backup, verification, installation-media and rebuild helpers.

## Repository layout

```text
.
├── scripts/
│   ├── audit-all.sh
│   ├── audit-home.sh
│   ├── audit-storage.sh
│   ├── audit-system.sh
│   └── smart-health.sh
├── docs/
│   └── recovery-workflow.md
├── reports/              # local output; ignored by Git
├── .gitignore
├── LICENSE
└── README.md
```

## Usage

Clone the repository and run the individual audits:

```bash
git clone https://github.com/tidus747/linux-recovery-toolkit.git
cd linux-recovery-toolkit

bash ./scripts/audit-system.sh
bash ./scripts/audit-storage.sh
bash ./scripts/audit-home.sh
bash ./scripts/smart-health.sh
```

Or collect them together:

```bash
bash ./scripts/audit-all.sh
```

Reports are written below `reports/`, which is deliberately excluded from Git.

## Privacy

Audit output can contain information that should not be published, including directory names, mount paths, installed software and hardware details.

The repository therefore stores tools and documentation only. Real machine reports, backups, inventories, secrets, SSH keys, GPG material and personal configuration must remain outside version control.

The SMART helper intentionally avoids printing disk serial numbers and WWNs.

## Safety model

The project is designed around progressively stronger levels of action:

```text
audit       -> read-only inspection
report      -> write local reports
apply       -> make reversible changes
destructive -> explicit, guarded destructive operations
```

v0.1 contains only the first two levels.

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
