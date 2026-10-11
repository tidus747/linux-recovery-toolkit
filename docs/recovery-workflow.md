# Recovery workflow

Linux Recovery Toolkit uses a conservative recovery workflow. The objective is not merely to reinstall Linux, but to understand the existing system before deciding what should survive.

## 1. Audit

Collect facts without modifying the system:

- distribution and version;
- kernel and systemd;
- desktop environment;
- disks and filesystems;
- mount layout;
- HOME usage;
- SMART health.

## 2. Assess

Review the evidence before changing anything.

Typical questions:

- Is either disk showing SMART warning signs?
- Is HOME mixing personal data with application state?
- Are old snapshots consuming space?
- Are there dedicated partitions that still have a purpose?
- Which data exists only on this machine?

## 3. Classify

Separate content into three categories.

### Persistent data

Documents, projects, photos, videos, datasets, books, virtual machines and other user-created material.

### Selective configuration

Configuration worth restoring intentionally, such as SSH configuration, GPG material or carefully selected application profiles.

### Rebuildable state

Caches, package downloads, application runtimes, old desktop settings, obsolete Wine prefixes and other state that can be recreated.

## 4. Back up

Create an external backup before repartitioning or reinstalling.

A backup should not depend on the disk that is about to be reformatted.

Encrypted HOME directories should be backed up from their mounted, decrypted view unless there is a deliberate reason to preserve the encrypted backing store as well.

## 5. Verify

Do not treat a completed copy command as proof of a valid backup.

Verify:

- expected directories exist;
- file counts and byte counts are plausible;
- representative files can be opened;
- checksums are used where appropriate.

## 6. Install

Only after backup verification should destructive installation work begin.

## 7. Restore selectively

Restore persistent data first. Reinstall applications cleanly. Restore configuration only when it has a clear reason to survive.

## 8. Rebuild and document

Record the packages, Flatpaks, services and machine-specific decisions needed to reproduce the system in the future.

## 9. Verify the new system

Check mounts, SMART health, services, networking, backups and application data before retiring the old copy.
