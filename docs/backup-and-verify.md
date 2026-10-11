# Backup and verification

The backup helpers are designed around one rule: a successful copy command is not enough to prove that a backup is usable.

## Requirements

- `rsync`
- a source directory that is readable
- an existing destination directory on the backup filesystem
- enough free space on the destination

For recovery work, the destination should be on a different physical disk from the source.

## 1. Start with a dry run

`backup-home.sh` does not write anything unless `--apply` is supplied.

```bash
bash ./scripts/backup-home.sh \
    --source "$HOME" \
    --destination /mnt/backup/home
```

Review the output before continuing.

## 2. Perform the copy

```bash
bash ./scripts/backup-home.sh \
    --source "$HOME" \
    --destination /mnt/backup/home \
    --apply
```

The script uses rsync archive mode, hard-link preservation, ACLs, extended attributes, numeric IDs and one-filesystem traversal.

It deliberately does not use `--delete` while copying. Existing files in the destination are not removed.

## 3. Verify the backup

```bash
bash ./scripts/verify-backup.sh \
    --source "$HOME" \
    --destination /mnt/backup/home
```

Verification uses an rsync checksum dry-run and reports differences in either tree. The `--delete` option is used only during the dry-run comparison so extra destination files can be detected without removing them.

A zero-difference result is a strong consistency check, but critical files should still be opened directly from the backup before destructive work begins.

## Encrypted HOME directories

When HOME is provided through a mounted encryption layer such as eCryptfs, back up the mounted, decrypted HOME while it is accessible.

Do not rely only on copying the encrypted backing directory unless preserving that encrypted representation is a deliberate recovery requirement.

## Optional exclusions

Nothing is excluded by default. This is intentional: a recovery backup should favor preservation over cleanup.

An example file is available at:

```text
config/backup.example.exclude
```

Use it only after reviewing the patterns:

```bash
bash ./scripts/backup-home.sh \
    --source "$HOME" \
    --destination /mnt/backup/home \
    --exclude-from ./config/backup.example.exclude
```

Use exactly the same exclusion file when verifying the backup.
