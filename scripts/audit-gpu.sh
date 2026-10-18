#!/usr/bin/env bash
# Read-only, privacy-conscious GPU and driver audit.

usage() {
    cat <<'USAGE'
Usage: bash ./scripts/audit-gpu.sh [--help]
Read-only checks: graphics devices, bound drivers, DRM connectors and
current-boot GPU log signatures. Exit 0 PASS, 1 WARN, 2 UNKNOWN.
A PASS does not guarantee a working graphical desktop.
USAGE
}

if (( $# > 0 )); then
    if (( $# == 1 )) && [[ "$1" == -h || "$1" == --help ]]; then
        usage
        exit 0
    fi
    printf 'Invalid arguments; see --help.\n' >&2
    exit 2
fi

command_exists() { command -v "$1" >/dev/null 2>&1; }
warnings=0
unknowns=0
warn() {
    printf '[WARN] %s\n' "$1"
    warnings=$((warnings + 1))
}
unknown() {
    printf '[UNKNOWN] %s\n' "$1"
    unknowns=$((unknowns + 1))
}

printf 'GPU audit (read-only)\n=====================\n'
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf 'Distribution: %s\n' "$PRETTY_NAME"
else
    unknown 'OS release unavailable.'
fi
printf 'Kernel: %s\n' "$(uname -r)"
printf 'Session type: %s\n' "$XDG_SESSION_TYPE"
printf 'Desktop: %s\n' "$XDG_CURRENT_DESKTOP"

printf '\n== Graphics devices / drivers ==\n'
if ! command_exists lspci; then
    unknown 'lspci unavailable; install pciutils.'
elif ! pci_output=$(lspci -nnk 2>/dev/null); then
    unknown 'lspci could not enumerate devices.'
else
    gpu_summary=$(printf '%s\n' "$pci_output" | awk '
        function finish() {
            if (inside && !bound)
                print "[UNKNOWN] No kernel driver bound for this GPU."
        }
        $1 ~ /^[[:xdigit:]:.]+$/ &&
        /VGA compatible controller|3D controller|Display controller/ {
            finish()
            count++
            inside=1
            bound=0
            description=$0
            sub(/^.*controller[^:]*:[[:space:]]*/, "", description)
            gsub(/\[[^]]*\]/, "", description)
            gsub(/[[:space:]]+/, " ", description)
            sub(/^[[:space:]]+/, "", description)
            sub(/[[:space:]]+$/, "", description)
            printf "GPU %d: %s\n", count, description
            next
        }
        inside && /^[^[:space:]]/ { finish(); inside=0; next }
        inside && /Kernel driver in use:/ {
            driver=$0
            sub(/^.*Kernel driver in use:[[:space:]]*/, "", driver)
            printf "  Driver in use: %s\n", driver
            bound=1
        }
        END {
            finish()
            if (count == 0) print "[UNKNOWN] No PCI graphics controller found."
            if (count > 1) printf "Multi-GPU configuration: %d controllers\n", count
        }
    ')
    printf '%s\n' "$gpu_summary"
    if [[ "$gpu_summary" == *"[UNKNOWN]"* ]]; then
        unknown 'PCI driver evidence incomplete.'
    fi
fi

printf '\n== Loaded GPU modules ==\n'
if command_exists lsmod; then
    lsmod 2>/dev/null | awk '
        NR>1 && $1 ~ /^(i915|xe|nouveau|nvidia|nvidia_drm|nvidia_modeset|amdgpu|radeon)$/ {
            printf "%s ", $1
            found=1
        }
        END { if (!found) printf "none reported"; printf "\n" }
    '
else
    printf 'Unavailable (lsmod not installed).\n'
fi

printf '\n== DRM connector status ==\n'
drm_root=$GPU_AUDIT_DRM_ROOT
if [[ -z "$drm_root" ]]; then drm_root=/sys/class/drm; fi
connectors=0
connected=0
undetermined=0
shopt -s nullglob
for status_path in "$drm_root"/card*-*/status; do
    [[ -f "$status_path" ]] || continue
    connectors=$((connectors + 1))
    if ! IFS= read -r status_value < "$status_path"; then
        undetermined=$((undetermined + 1))
        continue
    fi
    case "$status_value" in
        connected) connected=$((connected + 1)) ;;
        disconnected) ;;
        *) undetermined=$((undetermined + 1)) ;;
    esac
done
shopt -u nullglob
if (( connectors == 0 )); then
    unknown 'No readable DRM connector status available.'
else
    printf 'Connectors: %d total, %d connected, %d unknown\n' \
        "$connectors" "$connected" "$undetermined"
    if (( undetermined > 0 )); then
        unknown 'At least one connector state is unavailable.'
    fi
fi

printf '\n== Current boot GPU errors ==\n'
umask 077
log_file=$(mktemp) || {
    unknown 'Could not create temporary log buffer.'
    printf 'Result: UNKNOWN\n'
    exit 2
}
trap 'rm -f -- "$log_file"' EXIT

log_source=''
if command_exists journalctl &&
   journalctl -k -b --no-pager -o cat >"$log_file" 2>/dev/null &&
   [[ -s "$log_file" ]]; then
    log_source=journalctl
elif command_exists dmesg &&
     dmesg >"$log_file" 2>/dev/null &&
     [[ -s "$log_file" ]]; then
    log_source=dmesg
fi

if [[ -z "$log_source" ]]; then
    unknown 'Current-boot kernel messages unavailable or empty.'
else
    printf 'Evidence source: %s\n' "$log_source"
    signatures=$(awk '
        {
            s=tolower($0)
            if (s ~ /(nouveau|i915|amdgpu|radeon|drm)/ &&
                s ~ /(firmware|ucode)/ &&
                s ~ /(failed|missing|not found|unable|error)/) firmware++
            else if (s ~ /nouveau/ &&
                     s ~ /(fifo|pgraph|fault|hang|timeout|failed|error)/) nouveau++
            else if (s ~ /i915/ &&
                     s ~ /(gpu hang|reset|timeout|failed|error)/) intel++
            else if (s ~ /amdgpu/ &&
                     s ~ /(ring.*timeout|gpu reset|fault|failed|error)/) amd++
            else if (s ~ /(nvidia|nvrm)/ &&
                     s ~ /(xid|timeout|failed|error)/) nvidia++
        }
        END {
            printf "Firmware errors: %d\n", firmware+0
            printf "nouveau errors: %d\n", nouveau+0
            printf "i915 errors: %d\n", intel+0
            printf "amdgpu errors: %d\n", amd+0
            printf "NVIDIA errors: %d\n", nvidia+0
            printf "MATCH_COUNT=%d\n", firmware+nouveau+intel+amd+nvidia
        }
    ' "$log_file")
    printf '%s\n' "$signatures" | awk '!/^MATCH_COUNT=/'
    count=$(printf '%s\n' "$signatures" | awk -F= '/^MATCH_COUNT=/{print $2}')
    if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
        warn "$count selected GPU error signature(s) found."
    else
        printf 'No selected GPU error signatures found in accessible messages.\n'
    fi
fi

if [[ "$XDG_SESSION_TYPE" == x11 && -n "$DISPLAY" ]] && command_exists xrandr; then
    if providers=$(xrandr --listproviders 2>/dev/null); then
        provider_count=$(printf '%s\n' "$providers" | awk '/^Providers: number : /{print $4; exit}')
        printf '\nX11 provider count: %s\n' "$provider_count"
    fi
fi

printf '\nSummary: %d WARN, %d UNKNOWN\n' "$warnings" "$unknowns"
if (( warnings > 0 )); then
    printf 'Result: WARN\n'
    exit 1
fi
if (( unknowns > 0 )); then
    printf 'Result: UNKNOWN\n'
    exit 2
fi
printf 'Result: PASS (limited evidence; not proof of working graphics)\n'
