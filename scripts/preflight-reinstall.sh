#!/usr/bin/env bash

# Read-only preflight checks before a reinstall.
# The main goal is to catch the dangerous case where the backup lives on the
# same physical disk as the data that will be destroyed.

usage() {
    cat <<'USAGE'
Usage:
  preflight-reinstall.sh --backup DIR [--source DIR]

Required:
  --backup DIR     Existing backup directory.

Optional:
  --source DIR     Source data directory. Defaults to $HOME.
  -h, --help       Show this help.

The script does not modify filesystems, mounts or backup contents.
USAGE
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

pass() {
    printf '[PASS] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*"
}

fail() {
    printf '[FAIL] %s\n' "$*"
    failures=$((failures + 1))
}

resolve_block_source() {
    local path=$1
    local source=''
    local attempts=0

    while (( attempts < 8 )); do
        source=$(findmnt -T "$path" -no SOURCE 2>/dev/null || true)

        [[ -n "$source" ]] || return 1

        if [[ -b "$source" ]]; then
            printf '%s\n' "$source"
            return 0
        fi

        if [[ "$source" == /* && -e "$source" ]]; then
            path=$source
            attempts=$((attempts + 1))
            continue
        fi

        return 1
    done

    return 1
}

physical_disks() {
    local block_device=$1

    lsblk -s -nrpo NAME,TYPE "$block_device" 2>/dev/null |
        awk '$2 == "disk" {print $1}' |
        LC_ALL=C sort -u
}

have_common_line() {
    local left=$1
    local right=$2

    comm -12         <(printf '%s\n' "$left" | sed '/^$/d' | LC_ALL=C sort -u)         <(printf '%s\n' "$right" | sed '/^$/d' | LC_ALL=C sort -u) |
        grep -q .
}

source_dir=${HOME:-}
backup_dir=''
failures=0
unknown_checks=0

unknown() {
    printf '[UNKNOWN] %s\n' "$*"
    unknown_checks=$((unknown_checks + 1))
}

while (( $# > 0 )); do
    case "$1" in
        --source)
            (( $# >= 2 )) || die '--source requires a directory.'
            source_dir=$2
            shift 2
            ;;
        --backup)
            (( $# >= 2 )) || die '--backup requires a directory.'
            backup_dir=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

for command_name in findmnt lsblk readlink df comm grep sed awk; do
    command_exists "$command_name" || die "Required command not found: $command_name"
done

[[ -n "$source_dir" ]] || die 'Unable to determine the source directory.'
[[ -n "$backup_dir" ]] || die '--backup is required.'
[[ -d "$source_dir" ]] || die "Source directory does not exist: $source_dir"
[[ -d "$backup_dir" ]] || die "Backup directory does not exist: $backup_dir"

source_dir=$(readlink -f -- "$source_dir") || die 'Unable to resolve source directory.'
backup_dir=$(readlink -f -- "$backup_dir") || die 'Unable to resolve backup directory.'

printf 'Reinstall preflight\n'
printf '===================\n'
printf 'Source: %s\n' "$source_dir"
printf 'Backup: %s\n\n' "$backup_dir"

if [[ "$source_dir" == "$backup_dir" ]]; then
    fail 'Source and backup are the same directory.'
fi

source_block=$(resolve_block_source "$source_dir" || true)
backup_block=$(resolve_block_source "$backup_dir" || true)

if [[ -n "$source_block" ]]; then
    pass "Source block device resolved to $source_block"
else
    unknown 'Could not resolve the source to a block device.'
fi

if [[ -n "$backup_block" ]]; then
    pass "Backup block device resolved to $backup_block"
else
    unknown 'Could not resolve the backup to a block device.'
fi

if [[ -n "$source_block" && -n "$backup_block" ]]; then
    source_disks=$(physical_disks "$source_block")
    backup_disks=$(physical_disks "$backup_block")

    if [[ -z "$source_disks" || -z "$backup_disks" ]]; then
        unknown 'Could not resolve physical parent disks for both paths.'
    elif have_common_line "$source_disks" "$backup_disks"; then
        fail 'Source and backup share at least one physical disk.'
    else
        pass 'Source and backup are on different physical disks.'
    fi
fi

backup_options=$(findmnt -T "$backup_dir" -no OPTIONS 2>/dev/null || true)
case ",$backup_options," in
    *,rw,*)
        pass 'Backup filesystem is mounted read-write.'
        ;;
    *)
        warn 'Backup filesystem does not appear to be mounted read-write.'
        ;;
esac

source_fstype=$(findmnt -T "$source_dir" -no FSTYPE 2>/dev/null || true)
if [[ "$source_fstype" == "ecryptfs" ]]; then
    warn 'Source is mounted through eCryptfs. Back up the decrypted mounted view.'
else
    pass "Source filesystem type: ${source_fstype:-unknown}"
fi

if [[ -d /sys/firmware/efi ]]; then
    pass 'System is currently booted in UEFI mode.'
else
    warn 'System is not currently booted in UEFI mode.'
fi

printf '\nBackup filesystem space:\n'
df -hT "$backup_dir" 2>/dev/null || true

printf '\nManual checks still required:\n'
printf '[ ] Open representative files directly from the backup.\n'
printf '[ ] Preserve every user account that must survive the reinstall.\n'
printf '[ ] Save package and service inventories.\n'
printf '[ ] Review storage SMART self-test results.\n'
printf '[ ] Verify the installation ISO before writing installation media.\n'

printf '\n'
if (( failures > 0 )); then
    printf 'Preflight result: NOT READY (%d failure(s))\n' "$failures" >&2
    exit 1
fi

printf 'Preflight result: no blocking storage failures detected.\n'
printf 'This does not replace manual backup verification.\n'
