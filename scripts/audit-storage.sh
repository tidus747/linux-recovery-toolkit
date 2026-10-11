#!/usr/bin/env bash

# Read-only storage overview.
# UUIDs, PARTUUIDs and disk serial numbers are intentionally omitted.

print_section() {
    printf '\n== %s ==\n' "$1"
}

print_section "Block devices"
if command -v lsblk >/dev/null 2>&1; then
    lsblk -e 7 -o NAME,SIZE,TYPE,FSTYPE,FSVER,MOUNTPOINTS,MODEL,TRAN,ROTA
else
    printf 'lsblk is not available.\n' >&2
    exit 1
fi

print_section "Mounted filesystems"
if command -v findmnt >/dev/null 2>&1; then
    findmnt -t ext2,ext3,ext4,btrfs,xfs,vfat,f2fs,ntfs,exfat,ecryptfs
fi

print_section "Filesystem usage"
df -hT -x tmpfs -x devtmpfs 2>/dev/null || df -hT
