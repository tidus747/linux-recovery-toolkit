#!/usr/bin/env bash

# Copy one HOME directory to an existing backup directory with rsync.
# The default mode is dry-run. Use --apply to perform the copy.

usage() {
    cat <<'USAGE'
Usage:
  backup-home.sh --source DIR --destination DIR [options]

Required:
  --source DIR           Source HOME directory to copy.
  --destination DIR      Existing destination directory.

Options:
  --exclude-from FILE    Read rsync exclude patterns from FILE.
  --apply                Perform the copy. Without this flag, dry-run only.
  -h, --help             Show this help.

Examples:
  backup-home.sh --source "$HOME" --destination /mnt/backup/home
  backup-home.sh --source "$HOME" --destination /mnt/backup/home --apply
USAGE
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

source_dir=''
destination_dir=''
exclude_file=''
apply=false

while (( $# > 0 )); do
    case "$1" in
        --source)
            (( $# >= 2 )) || die '--source requires a directory.'
            source_dir=$2
            shift 2
            ;;
        --destination)
            (( $# >= 2 )) || die '--destination requires a directory.'
            destination_dir=$2
            shift 2
            ;;
        --exclude-from)
            (( $# >= 2 )) || die '--exclude-from requires a file.'
            exclude_file=$2
            shift 2
            ;;
        --apply)
            apply=true
            shift
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

command_exists rsync || die 'rsync is required.'
command_exists readlink || die 'readlink is required.'

[[ -n "$source_dir" ]] || die '--source is required.'
[[ -n "$destination_dir" ]] || die '--destination is required.'
[[ -d "$source_dir" ]] || die "Source directory does not exist: $source_dir"
[[ -d "$destination_dir" ]] || die "Destination directory does not exist: $destination_dir"

if [[ -n "$exclude_file" && ! -f "$exclude_file" ]]; then
    die "Exclude file does not exist: $exclude_file"
fi

source_dir=$(readlink -f -- "$source_dir") || die 'Unable to resolve source directory.'
destination_dir=$(readlink -f -- "$destination_dir") || die 'Unable to resolve destination directory.'

[[ "$source_dir" != "$destination_dir" ]] || die 'Source and destination are the same directory.'

case "$destination_dir/" in
    "$source_dir/"*)
        die 'Destination must not be inside the source directory.'
        ;;
esac

case "$source_dir/" in
    "$destination_dir/"*)
        die 'Source must not be inside the destination directory.'
        ;;
esac

printf 'Linux Recovery Toolkit backup\n'
printf '=============================\n'
printf 'Source:      %s\n' "$source_dir"
printf 'Destination: %s\n' "$destination_dir"

if command_exists findmnt; then
    source_fs=$(findmnt -T "$source_dir" -no SOURCE,FSTYPE 2>/dev/null || true)
    destination_fs=$(findmnt -T "$destination_dir" -no SOURCE,FSTYPE 2>/dev/null || true)
    printf 'Source FS:   %s\n' "${source_fs:-unknown}"
    printf 'Target FS:   %s\n' "${destination_fs:-unknown}"
fi

printf '\nA recovery backup should live on a different physical disk.\n'
printf 'This script does not delete files from the destination.\n\n'

rsync_args=(
    --archive
    --hard-links
    --acls
    --xattrs
    --one-file-system
    --numeric-ids
    --human-readable
    --info=progress2
    --protect-args
)

if [[ -n "$exclude_file" ]]; then
    rsync_args+=(--exclude-from="$exclude_file")
fi

if [[ "$apply" == false ]]; then
    rsync_args+=(--dry-run --itemize-changes)
    printf 'Mode: DRY RUN\n'
    printf 'No files will be written. Add --apply after reviewing the output.\n\n'
else
    printf 'Mode: APPLY\n'
    printf 'Files will now be copied. Existing destination files may be updated.\n\n'
fi

if ! rsync "${rsync_args[@]}" "$source_dir/" "$destination_dir/"; then
    die 'rsync did not complete successfully.'
fi

if [[ "$apply" == false ]]; then
    printf '\nDry run completed. Review the changes before using --apply.\n'
else
    printf '\nBackup copy completed. Run verify-backup.sh before relying on it.\n'
fi
