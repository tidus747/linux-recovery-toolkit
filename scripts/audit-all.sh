#!/usr/bin/env bash

# Collect all read-only audit reports into a local Git-ignored directory.

umask 077

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
timestamp=$(date '+%Y%m%d-%H%M%S')
report_dir="$repo_dir/reports/$timestamp"
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

run_report system "$script_dir/audit-system.sh"
run_report storage "$script_dir/audit-storage.sh"
run_report home "$script_dir/audit-home.sh"
run_report smart "$script_dir/smart-health.sh"

printf '\nReports written to:\n%s\n' "$report_dir"
printf '\nTreat these reports as private machine data. They are ignored by Git.\n'
if (( failed_reports > 0 )); then
    printf 'Report collection INCOMPLETE: %d report(s) failed.\n' "$failed_reports" >&2
    exit 1
fi
