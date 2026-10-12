export const recoveryGuides = [
  {
    "slug": "backup-filesystems",
    "title": "Backup targets: Linux filesystems, NTFS and exFAT",
    "summary": "A copied file tree is not necessarily a restorable Linux HOME.",
    "inspection": "Use a separate physical drive for the backup and inspect its actual filesystem with `findmnt -T /mnt/backup -o TARGET,SOURCE,FSTYPE,OPTIONS`. On ext4, btrfs or xfs, Linux metadata features are generally available subject to mount configuration and privileges. On NTFS/exFAT the filesystem may not support native Linux ownership, ACLs, xattrs and hardlink semantics as rsync expects. The v0.3 script unconditionally requests these flags; failures or silent metadata differences can make a full HOME recovery unreliable.",
    "decision": "A portable data-only copy and a Linux metadata-preserving archive are different products. v0.4 will make this distinction explicit. Until then do not promise identical restore semantics on NTFS/exFAT.",
    "verification": "Run the helper first without `--apply`; inspect the destination, capacity, filesystem, paths and proposed changes. For irreplaceable data, maintain another independent copy, verify it and test that files can be opened. Do not format the source based on a successful copy message."
  },
  {
    "slug": "encrypted-home",
    "title": "Encrypted HOME recovery",
    "summary": "Back up the decrypted mounted user data, not an opaque store by default.",
    "inspection": "First determine the actual encryption mechanism and mounted layout using read-only inspection. LUKS, fscrypt and eCryptfs have different recovery requirements; a command for one system cannot be assumed appropriate for another.",
    "decision": "For eCryptfs, when the account is accessible and mounted normally, the readable HOME view is usually the useful backup source. Preserve the ability to unlock the encrypted data separately, with securely held credentials or recovery material. Do not include keys in GitHub reports.",
    "verification": "Verify restored copies from their intended destination on a separate drive. Before reinstall, establish which users and encrypted stores need to survive."
  },
  {
    "slug": "reinstall-checklist",
    "title": "Preflight before reinstall",
    "summary": "A reinstall changes disk state. Documentation does not authorize destructive operations.",
    "inspection": "Audit devices and identify the exact target disk using `lsblk`, `findmnt`, firmware mode and filesystem layout. Record existing partitions, user accounts, services, packages and backup locations. Inspect disk health and verify the installer image against its vendor-published checksum.",
    "decision": "Run `preflight-reinstall.sh --source \"$HOME\" --backup /mnt/backup/home` but remember v0.3 can return zero if disk separation cannot be determined. UNKNOWN is not PASS.",
    "verification": "Before partitioning, inspect real files from the external backup, ensure physically independent storage, preserve all required users, understand encryption and have rollback media. Treat backup restoration as an independent test."
  },
  {
    "slug": "rebuild-inventory",
    "title": "Rebuild inventory and selective restore",
    "summary": "Preserve knowledge without blindly copying stale application state.",
    "inspection": "Capture package and systemd inventory, then classify HOME into user-created content, optional configuration and regenerable caches. These inventories are not executable restore plans and may differ between package managers.",
    "decision": "Reinstall applications from supported distribution repositories rather than replaying an old list without review. Inspect enabled systemd units before enabling them on the new installation.",
    "verification": "Restore data first, then selected configuration. Verify user ownership, permissions, mount points, services, network connectivity and backups on the new installation."
  },
  {
    "slug": "privacy",
    "title": "Privacy and report handling",
    "summary": "Audits are read-only but their output can disclose private system information.",
    "inspection": "Directory names, usernames, mount paths, package lists and services may expose personal or security-relevant information. `audit-storage.sh` deliberately omits serial/UUID fields, but device models and mount paths remain visible.",
    "decision": "Never upload raw HOME backups, SSH/GPG keys, encrypted credentials, inventory files or complete system reports to public issue threads. Prefer a redacted, minimal excerpt that reproduces the problem.",
    "verification": "Until private output permissions are enforced in v0.4, explicitly check report permissions with `stat -c '%a %n' reports/*` and store outputs securely."
  }
] as const;
