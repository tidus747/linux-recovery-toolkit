# Linux Recovery Toolkit

A conservative toolkit for auditing, backing up and rebuilding Linux systems without carrying years of hidden state from one installation to the next.

<p align="center">
  <img src="assets/mascot/linux-recovery-bot.png" alt="Linux Recovery Toolkit maintenance bot" width="240">
</p>

<p align="center">
  Careful inspection first. Safe cleanup second. Destructive actions only when everything is understood and backed up.
</p>

The project follows one rule above all others:

> Observe first. Change later.

## Why this project exists

Reinstalling Linux should not mean carrying years of hidden state, stale configuration, caches and legacy application data into the next system.

Linux Recovery Toolkit aims to make that process deliberate and reproducible:

- audit first
- understand the system before changing it
- classify what is worth preserving
- back up carefully
- verify before destructive work
- rebuild cleanly

## Meet the recovery bot

The maintenance bot represents the spirit of the project: inspect, repair, clean and recover without turning system administration into guesswork.

It is also a reminder that safe recovery should feel methodical and calm, not chaotic.

## Current status

### v0.1 - Audit and inventory

Read-only inspection tools:

- `audit-system.sh` - distribution, kernel, systemd, desktop and basic hardware
- `audit-storage.sh` - disks, filesystems, mounts and space usage
- `audit-home.sh` - top-level HOME usage, including hidden directories
- `smart-health.sh` - focused SMART health information without disk serial numbers
- `audit-all.sh` - collect the above reports into a local timestamped directory

### v0.2 - Backup and verify

The next layer adds guarded backup tooling:

- `backup-home.sh` - rsync backup helper that is dry-run by default
- `verify-backup.sh` - checksum-based rsync verification without modifying the backup
- optional exclusion patterns
- documentation for encrypted HOME recovery

## Workflow

```text
Audit -> Assess -> Classify -> Back up -> Verify -> Install -> Restore -> Rebuild
```

## Repository layout

```text
.
|-- assets/
|   `-- mascot/
|       `-- linux-recovery-bot.webp
|-- config/
|   `-- backup.example.exclude
|-- docs/
|   |-- backup-and-verify.md
|   `-- recovery-workflow.md
|-- scripts/
|   |-- audit-all.sh
|   |-- audit-home.sh
|   |-- audit-storage.sh
|   |-- audit-system.sh
|   |-- backup-home.sh
|   |-- smart-health.sh
|   `-- verify-backup.sh
|-- reports/              # local output, ignored by Git
|-- .gitignore
|-- LICENSE
`-- README.md
```

## Audit usage

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

## Backup usage

Start with a dry run:

```bash
bash ./scripts/backup-home.sh \
    --source "$HOME" \
    --destination /mnt/backup/home
```

After reviewing the proposed changes, perform the copy:

```bash
bash ./scripts/backup-home.sh \
    --source "$HOME" \
    --destination /mnt/backup/home \
    --apply
```

Then verify it:

```bash
bash ./scripts/verify-backup.sh \
    --source "$HOME" \
    --destination /mnt/backup/home
```

See [docs/backup-and-verify.md](docs/backup-and-verify.md) before using these tools for a real migration.

## Privacy

Audit output can contain information that should not be published, including directory names, mount paths, installed software and hardware details.

The repository stores tools and documentation only. Real machine reports, backups, inventories, secrets, SSH keys, GPG material and personal configuration must remain outside version control.

The SMART helper intentionally avoids printing disk serial numbers and WWNs.

## Safety model

The project is designed around progressively stronger levels of action:

```text
audit       -> read-only inspection
report      -> write local reports
apply       -> make reversible changes
destructive -> explicit, guarded destructive operations
```

The backup helper is dry-run by default and requires `--apply` before writing files.

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
