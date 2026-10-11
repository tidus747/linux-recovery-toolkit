# Rebuild inventory and reinstall preflight

A clean reinstall should preserve knowledge about the old system without blindly preserving its old state.

The v0.3 helpers collect the information that is useful for rebuilding a machine and add a storage safety check before destructive work begins.

## Package inventory

Run:

```bash
bash ./scripts/inventory-packages.sh > packages.txt
```

Depending on what is installed, the report can include:

- APT packages marked as manually installed
- Flatpak applications
- Snap packages
- pipx applications
- global npm packages
- Cargo-installed applications

The report is an inventory, not an automatic restore script. Package names and availability can change between distributions and releases.

## systemd inventory

Run:

```bash
bash ./scripts/inventory-services.sh > services.txt
```

The report includes enabled system services and timers. When the current session exposes a user systemd manager, enabled user services and timers are included as well.

Do not re-enable every old unit automatically after a reinstall. Use the inventory to decide which behavior should be recreated.

## Reinstall preflight

Before repartitioning or formatting a machine, run:

```bash
bash ./scripts/preflight-reinstall.sh \
    --source "$HOME" \
    --backup /mnt/backup/home
```

The script checks:

- source and backup paths
- the backing block devices
- whether source and backup share a physical disk
- whether the backup filesystem is mounted read-write
- eCryptfs detection
- current UEFI boot mode
- free space on the backup filesystem

The most important blocking check is physical disk separation. A backup stored on another partition of the disk that is about to be erased is not a safe recovery backup.

## Privacy

Inventory output can reveal installed applications and enabled services. Store generated reports locally and treat them as machine-specific data.

The repository does not include real inventory output.
