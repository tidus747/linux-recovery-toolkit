#!/usr/bin/env bash
# Uses mocks and a fake DRM sysfs tree; never queries real GPUs.
test_dir=$(cd -- "$(dirname -- "$0")" && pwd) || exit 1
repo_dir=$(cd -- "$test_dir/.." && pwd) || exit 1
sandbox=$(mktemp -d) || exit 1
trap 'rm -rf -- "$sandbox"' EXIT
mkdir -p "$sandbox/bin" "$sandbox/drm/card0-eDP-1" || exit 1
printf 'connected\n' >"$sandbox/drm/card0-eDP-1/status"
export GPU_AUDIT_DRM_ROOT="$sandbox/drm"
export PATH="$sandbox/bin:$PATH"
export XDG_SESSION_TYPE=wayland

cat >"$sandbox/bin/lspci" <<'MOCK'
#!/usr/bin/env bash
case "$GPU_PCI_CASE" in
    unavailable) exit 1 ;;
    missing) exit 0 ;;
esac
cat <<'PCI'
00:02.0 VGA compatible controller [0300]: Intel Corporation HD Graphics 4000 [8086:0166]
        Kernel driver in use: i915
01:00.0 3D controller [0302]: NVIDIA Corporation GF108M [GeForce GT 635M] [10de:0de3]
        Kernel driver in use: nouveau
PCI
MOCK
cat >"$sandbox/bin/journalctl" <<'MOCK'
#!/usr/bin/env bash
case "$GPU_LOG_CASE" in
    clean) printf 'Linux version test kernel\nUSB initialized\n' ;;
    nouveau) printf 'nouveau 0000:01:00.0: fifo: PGRAPH fault\n' ;;
    intel) printf 'i915 0000:00:02.0: GPU HANG detected\n' ;;
    firmware) printf 'nouveau 0000:01:00.0: firmware nvc1_fuc084 missing\n' ;;
    unavailable) exit 1 ;;
esac
MOCK
cat >"$sandbox/bin/dmesg" <<'MOCK'
#!/usr/bin/env bash
case "$GPU_DMESG_CASE" in
    clean) printf 'Linux version fallback kernel\n' ;;
    unavailable) exit 1 ;;
esac
MOCK
cat >"$sandbox/bin/lsmod" <<'MOCK'
#!/usr/bin/env bash
printf 'Module Size Used by\ni915 1000 1\nnouveau 1000 1\n'
MOCK
chmod +x "$sandbox/bin/"* || exit 1

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
run_case() {
    local name=$1 pci=$2 journal=$3 dmesg_case=$4 expected=$5 marker=$6
    local output='' status=0
    export GPU_PCI_CASE="$pci" GPU_LOG_CASE="$journal" GPU_DMESG_CASE="$dmesg_case"
    output=$(bash "$repo_dir/scripts/audit-gpu.sh" 2>&1) || status=$?
    if [[ "$status" != "$expected" || "$output" != *"$marker"* ]]; then
        fail "$name: expected exit $expected + $marker; actual $status: $output"
    fi
    if [[ "$output" == *'0000:01:00.0'* || "$output" == *'8086:0166'* ||
          "$output" == *'Linux version test kernel'* ]]; then
        fail "$name: unredacted PCI or kernel log content detected"
    fi
    printf 'PASS: %s\n' "$name"
}
run_case healthy hybrid clean unavailable 0 'Result: PASS'
run_case nouveau-error hybrid nouveau unavailable 1 'nouveau errors: 1'
run_case intel-hang hybrid intel unavailable 1 'i915 errors: 1'
run_case missing-firmware hybrid firmware unavailable 1 'Firmware errors: 1'
run_case pci-unavailable unavailable clean unavailable 2 'Result: UNKNOWN'
run_case pci-missing missing clean unavailable 2 'No PCI graphics controller'
run_case kernel-unavailable hybrid unavailable unavailable 2 'kernel messages unavailable or empty'
run_case fallback hybrid unavailable clean 0 'Evidence source: dmesg'

export GPU_AUDIT_DRM_ROOT="$sandbox/empty"
mkdir -p "$GPU_AUDIT_DRM_ROOT" || exit 1
run_case drm-unavailable hybrid clean unavailable 2 'DRM connector status'
printf 'PASS: GPU audit mock test suite\n'
