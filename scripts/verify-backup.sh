#!/usr/bin/env bash

# Compare a source tree with a backup using an rsync checksum dry-run.
# No destination files are modified.

usage() {
    cat <<'USAGE'
Usage:
  verify-backup.sh --source DIR --destination DIR [options]

Required:
  --source DIR           Original source directory.
  --destination DIR      Backup directory to verify.

Options:
  --exclude-from FILE    Use the same rsync exclude patterns as the backup.
  -h, --help             Show this help.

The verification reads file contents on both sides and reports any differences.
The rsync --delete option is used only together with --dry-run so that extra
files in the destination are reported, not removed.
USAGE
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

source_dir=''
destination_dir=''
exclude_file=''

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
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

command -v rsync >/dev/null 2>&1 || die 'rsync is required.'
command -v readlink >/dev/null 2>&1 || die 'readlink is required.'

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

tmp_report=$(mktemp) || die 'Unable to create a temporary report.'
trap 'rm -f -- "$tmp_report"' EXIT

rsync_args=(
    --archive
    --hard-links
    --acls
    --xattrs
    --one-file-system
    --numeric-ids
    --checksum
    --dry-run
    --delete
    --itemize-changes
    --out-format=%i\ %n%L
    --protect-args
)

if [[ -n "$exclude_file" ]]; then
    rsync_args+=(--exclude-from="$exclude_file")
fi

printf 'Verifying backup contents...\n'
printf 'Source:      %s\n' "$source_dir"
printf 'Destination: %s\n\n' "$destination_dir"

if ! rsync "${rsync_args[@]}" "$source_dir/" "$destination_dir/" >"$tmp_report"; then
    die 'rsync verification did not complete successfully.'
fi

if [[ -s "$tmp_report" ]]; then
    printf 'Verification found differences:\n\n'
    cat "$tmp_report"
    printf '\nThe backup does not currently match the source.\n' >&2
    exit 2
fi

printf 'Verification passed: no rsync differences were found.\n'
printf 'For critical data, also open representative files from the backup manually.\n'
