#!/usr/bin/env bash
# Mock-backed tests for SMART status handling; no actual drives are accessed.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
repo_dir=$(cd -- "$script_dir/.." && pwd) || exit 1
tmp_dir=$(mktemp -d) || exit 1
trap 'rm -rf -- "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/bin"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$tmp_dir/bin/lsblk" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
    '-dn -p -o NAME,TYPE') printf '/dev/mock-good disk\n/dev/mock-bad disk\n' ;;
    *'/dev/mock-good'*|*'/dev/mock-bad'*)
        if [[ "$*" == *' -o TYPE '* ]]; then printf 'disk\n'; else printf '16G Model USB 0\n'; fi ;;
    *) exit 1 ;;
esac
MOCK
cat >"$tmp_dir/bin/smartctl" <<'MOCK'
#!/usr/bin/env bash
[[ "$*" == *'-q noserial'* ]] || { printf 'missing noserial flag\n' >&2; exit 1; }
case "$MOCK_CASE" in
    good) printf 'SMART overall-health self-assessment test result: PASSED\n'; exit 0 ;;
    failing) printf 'SMART overall-health self-assessment test result: FAILED!\n'; exit 8 ;;
    old-failure) printf 'SMART Health Status: OK\n'; exit 32 ;;
    access) printf 'permission denied\n' >&2; exit 2 ;;
    usb) printf 'USB bridge unsupported\n' >&2; exit 2 ;;
    no-health) printf 'No SMART information available\n'; exit 0 ;;
    mixed)
        if [[ "$*" == *'/dev/mock-bad'* ]]; then
            printf 'SMART Health Status: FAILED!\n'; exit 8
        fi
        printf 'SMART Health Status: OK\n'; exit 0 ;;
    *) exit 1 ;;
esac
MOCK
cat >"$tmp_dir/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
exec "$@"
MOCK
chmod +x "$tmp_dir/bin/lsblk" "$tmp_dir/bin/smartctl" "$tmp_dir/bin/sudo" || exit 1
export PATH="$tmp_dir/bin:$PATH"

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

run_case() {
    local name=$1 expected_exit=$2 expected_message=$3
    shift 3
    export MOCK_CASE="$name"
    local output='' status=''
    capture output status bash "$repo_dir/scripts/smart-health.sh" "$@"
    if [[ "$status" != "$expected_exit" || "$output" != *"$expected_message"* ]]; then
        fail "$name: expected exit $expected_exit and $expected_message; got $status: $output"
    fi
    if [[ "$output" == *'Serial Number'* || "$output" == *'WWN'* ]]; then
        fail "$name: device identity leaked"
    fi
}

run_case good 0 '[PASS]' /dev/mock-good
run_case failing 1 '[WARN]' /dev/mock-good
run_case old-failure 1 '[WARN]' /dev/mock-good
run_case access 2 '[UNKNOWN]' /dev/mock-good
run_case usb 2 '[UNKNOWN]' --device-type sat /dev/mock-good
run_case no-health 2 '[UNKNOWN]' /dev/mock-good
run_case mixed 1 '1 WARN'

export MOCK_CASE=good
capture output status bash "$repo_dir/scripts/smart-health.sh" /dev/not-a-disk
[[ "$status" == 2 && "$output" == *'[UNKNOWN]'* ]] || fail 'invalid device should be unknown'

printf 'PASS: SMART healthy, failing, history, unavailable, USB, invalid and multi-device scenarios\n'
