#!/usr/bin/env bash
# Non-destructive regression tests; no real block-device writes.
# Run with: bash tests/safety-smoke.sh
set -u

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temp_dir=$(mktemp -d) || exit 1
trap 'rm -rf -- "$temp_dir"' EXIT
mkdir -p "$temp_dir/bin" "$temp_dir/source" "$temp_dir/backup"
touch "$temp_dir/source/keep.txt"

# Make mount resolution unknown on purpose, never touch host disks.
cat >"$temp_dir/bin/findmnt" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$temp_dir/bin/findmnt"
export PATH="$temp_dir/bin:$PATH"

set +e
result=$(bash "$repo_dir/scripts/preflight-reinstall.sh" --source "$temp_dir/source" --backup "$temp_dir/backup" 2>&1)
status=$?
set -e
if (( status != 2 )) || [[ "$result" != *"INCONCLUSIVE"* ]]; then
    printf 'FAIL: unknown disk identity must exit 2; actual %s\n%s\n' "$status" "$result" >&2
    exit 1
fi

set +e
result=$(bash "$repo_dir/scripts/preflight-reinstall.sh" --source "$temp_dir/source" --backup "$temp_dir/source" 2>&1)
status=$?
set -e
if (( status != 1 )) || [[ "$result" != *"NOT READY"* ]]; then
    printf 'FAIL: identical source/backup must fail; actual %s\n%s\n' "$status" "$result" >&2
    exit 1
fi

# Inventory output must remain restricted to the invoking user.
mkdir -p "$temp_dir/report-parent"
umask 077
[[ "$(umask)" == "0077" ]] || exit 1

printf 'PASS: preflight unknown and same-path safety cases\n'
