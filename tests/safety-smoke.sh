#!/usr/bin/env bash
# Tests run only against temporary directories and mocked host commands.
# No real disks are probed, mounted or modified.

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
temp_dir=$(mktemp -d) || exit 1
trap 'rm -rf -- "$temp_dir"' EXIT

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

capture() {
    local output_var=$1
    local status_var=$2
    shift 2
    local captured_output=''
    local captured_status=0

    captured_output=$("$@" 2>&1) || captured_status=$?
    printf -v "$output_var" '%s' "$captured_output"
    printf -v "$status_var" '%s' "$captured_status"
}

mkdir -p "$temp_dir/bin" "$temp_dir/source" "$temp_dir/backup" || exit 1
printf 'data\n' >"$temp_dir/source/keep.txt"

# Simulate missing disk identity, even if the CI runner has real mounts.
cat >"$temp_dir/bin/findmnt" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$temp_dir/bin/findmnt" || exit 1
export PATH="$temp_dir/bin:$PATH"

capture output status bash "$repo_dir/scripts/preflight-reinstall.sh" \
    --source "$temp_dir/source" --backup "$temp_dir/backup"
[[ "$status" == 2 && "$output" == *"INCONCLUSIVE"* ]] ||
    die "unknown physical disks must be INCONCLUSIVE (2); status=$status: $output"

capture output status bash "$repo_dir/scripts/preflight-reinstall.sh" \
    --source "$temp_dir/source" --backup "$temp_dir/source"
[[ "$status" == 1 && "$output" == *"NOT READY"* ]] ||
    die "identical source/backup must be NOT READY (1); status=$status: $output"

printf 'PASS: preflight unknown and same-path checks\n'

# Build independent fixtures with scripts that intentionally lack executable bits.
# This tests that aggregators use 'bash' to run helper files.
make_collector() {
    local name=$1
    local script_name=$2
    shift 2
    local helper=''
    local dir="$temp_dir/$name/scripts"

    mkdir -p "$dir" || die "cannot make $dir"
    cp "$repo_dir/scripts/$script_name" "$dir/" || die "cannot copy $script_name"
    for helper in "$@"; do
        printf '#!/usr/bin/env bash\nprintf "example report\\n"\n' >"$dir/$helper.sh"
        chmod 0644 "$dir/$helper.sh" || die "cannot set helper mode"
    done
}

assert_private_report() {
    local report_root=$1
    local failed_report_name=$2
    local report=''
    local directory=''
    local folder_mode=''
    local file_mode=''

    report=$(find "$report_root" -type f -name "$failed_report_name" -print -quit) ||
        die "cannot locate report"
    [[ -n "$report" ]] || die "missing $failed_report_name in $report_root"
    directory=$(dirname -- "$report") || die "cannot resolve report directory"
    folder_mode=$(stat -c '%a' "$directory") || die "cannot stat report directory"
    file_mode=$(stat -c '%a' "$report") || die "cannot stat report file"
    [[ "$folder_mode" == 700 && "$file_mode" == 600 ]] ||
        die "report permissions are not private: folder=$folder_mode file=$file_mode"
}

# Aggregators must preserve failed child output and report the failure.
make_collector audit audit-all audit-system audit-storage audit-home smart-health
printf '#!/usr/bin/env bash\nprintf "SMART unavailable\\n" >&2\nexit 7\n' \
    >"$temp_dir/audit/scripts/smart-health.sh"
chmod 0644 "$temp_dir/audit/scripts/smart-health.sh" || exit 1

capture output status bash "$temp_dir/audit/scripts/audit-all.sh"
[[ "$status" == 1 && "$output" == *"INCOMPLETE: 1 report(s) failed"* ]] ||
    die "audit collector lost a failing child; status=$status: $output"
assert_private_report "$temp_dir/audit/reports" "smart.txt"
printf 'PASS: audit failure propagation and report privacy\n'

make_collector inventory inventory-all inventory-packages inventory-services
printf '#!/usr/bin/env bash\nprintf "systemd unavailable\\n" >&2\nexit 7\n' \
    >"$temp_dir/inventory/scripts/inventory-services.sh"
chmod 0644 "$temp_dir/inventory/scripts/inventory-services.sh" || exit 1

capture output status bash "$temp_dir/inventory/scripts/inventory-all.sh"
[[ "$status" == 1 && "$output" == *"INCOMPLETE: 1 report(s) failed"* ]] ||
    die "inventory collector lost a failing child; status=$status: $output"
assert_private_report "$temp_dir/inventory/reports" "services.txt"
printf 'PASS: inventory failure propagation and report privacy\n'

# Also verify that success remains success with non-executable child scripts.
make_collector audit-ok audit-all audit-system audit-storage audit-home smart-health
capture output status bash "$temp_dir/audit-ok/scripts/audit-all.sh"
[[ "$status" == 0 ]] || die "successful audit reports should exit zero: $output"
assert_private_report "$temp_dir/audit-ok/reports" "system.txt"

make_collector inventory-ok inventory-all inventory-packages inventory-services
capture output status bash "$temp_dir/inventory-ok/scripts/inventory-all.sh"
[[ "$status" == 0 ]] || die "successful inventory reports should exit zero: $output"
assert_private_report "$temp_dir/inventory-ok/reports" "packages.txt"

printf 'PASS: successful collectors with non-executable helpers\n'
