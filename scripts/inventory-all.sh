#!/usr/bin/env bash

# Collect rebuild-oriented inventories into a local Git-ignored directory.

umask 077

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
timestamp=$(date '+%Y%m%d-%H%M%S')
report_dir="$repo_dir/reports/rebuild-$timestamp"
failed_reports=0

if ! mkdir -p "$report_dir"; then
    printf 'Unable to create report directory: %s\n' "$report_dir" >&2
    exit 1
fi

run_report() {
    local name=$1
    local script=$2

    printf 'Collecting %s...\n' "$name"

    if ! bash "$script" >"$report_dir/$name.txt" 2>&1; then
        printf '  %s FAILED; inspect %s.txt\n' "$name" "$name" >&2
        failed_reports=$((failed_reports + 1))
    fi
}

run_report packages "$script_dir/inventory-packages.sh"
run_report services "$script_dir/inventory-services.sh"

printf '\nRebuild inventory written to:\n%s\n' "$report_dir"
printf '\nTreat these files as private machine data. They are ignored by Git.\n'
if (( failed_reports > 0 )); then
    printf 'Inventory INCOMPLETE: %d report(s) failed.\n' "$failed_reports" >&2
    exit 1
fi
