#!/usr/bin/env bash

# Read-only, privacy-conscious SMART inspection.
# smartctl uses a bitmask exit status; do not hide it behind a formatter.

usage() {
    cat <<'USAGE'
Usage:
  smart-health.sh [--device-type TYPE] [DEVICE ...]

Options:
  --device-type TYPE  Pass an explicit smartctl -d TYPE for USB/RAID adapters.
  -h, --help          Show this help.

Without DEVICE arguments, all disks reported by lsblk are inspected.
This command reads SMART data; it does not start self-tests or change disks.
Exit status: 0 = PASS, 1 = WARN (health evidence), 2 = UNKNOWN/incomplete.
USAGE
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

umask 077

device_type=''
devices=()

while (( $# > 0 )); do
    case "$1" in
        --device-type)
            (( $# >= 2 )) || die '--device-type needs a value.'
            [[ -n "$2" ]] || die 'Device type cannot be empty.'
            device_type=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            die "Unknown option: $1"
            ;;
        *)
            devices+=("$1")
            shift
            ;;
    esac
done

command_exists smartctl || die 'smartctl was not found (smartmontools package).'
command_exists lsblk || die 'lsblk was not found.'
command_exists awk || die 'awk was not found.'
command_exists grep || die 'grep was not found.'

if (( EUID != 0 )) && ! command_exists sudo; then
    die 'sudo is required for this user to read SMART data.'
fi

if (( ${#devices[@]} == 0 )); then
    listing=$(lsblk -dn -p -o NAME,TYPE 2>/dev/null) || die 'Unable to enumerate disk devices.'
    while read -r path kind; do
        if [[ "$kind" == disk && -n "$path" ]]; then
            devices+=("$path")
        fi
    done <<< "$listing"
fi

(( ${#devices[@]} > 0 )) || die 'No disks found.'

tmp_output=$(mktemp) || die 'Could not create a temporary SMART report.'
trap 'rm -f -- "$tmp_output"' EXIT

warning_count=0
unknown_count=0
pass_count=0

for device in "${devices[@]}"; do
    printf '\n== %s ==\n' "$device"

    kind=$(lsblk -dn -o TYPE -- "$device" 2>/dev/null) || kind=''
    if [[ "$kind" != disk ]]; then
        printf '[UNKNOWN] Not a readable disk device (lsblk type: %s).\n' "${kind:-unavailable}"
        unknown_count=$((unknown_count + 1))
        continue
    fi

    if description=$(lsblk -dn -o SIZE,MODEL,TRAN,ROTA -- "$device" 2>/dev/null); then
        printf 'Device: %s\n' "$description"
    fi

    smart_args=(-q noserial -H -A -l selftest)
    if [[ -n "$device_type" ]]; then
        smart_args+=(-d "$device_type")
    fi
    smart_args+=("$device")

    smart_status=0
    if (( EUID == 0 )); then
        smartctl "${smart_args[@]}" >"$tmp_output" 2>/dev/null || smart_status=$?
    else
        sudo smartctl "${smart_args[@]}" >"$tmp_output" 2>/dev/null || smart_status=$?
    fi

    # Show only selected fields; suppress serials/WWNs and raw diagnostics.
    awk '
        /^SMART overall-health self-assessment test result:/ ||
        /^SMART Health Status:/ ||
        /Reallocated_Sector_Ct/ ||
        /Power_On_Hours/ ||
        /Current_Pending_Sector/ ||
        /Offline_Uncorrectable/ ||
        /UDMA_CRC_Error_Count/ ||
        /CRC_Error_Count/ ||
        /Wear_Leveling_Count/ ||
        /Percentage Used/ ||
        /Temperature_Celsius/ ||
        /Airflow_Temperature_Cel/ ||
        /^# [0-9]+/ ||
        /Completed without error/ ||
        /Completed: read failure/
    ' "$tmp_output"

    if (( (smart_status & 248) != 0 )) ||
        grep -Eiq '^(SMART overall-health self-assessment test result:|SMART Health Status:).*(FAIL|BAD)' "$tmp_output"; then
        printf '[WARN] SMART reported health concerns (smartctl status=%d).\n' "$smart_status"
        warning_count=$((warning_count + 1))
        if (( (smart_status & 7) != 0 )); then
            printf '       Some SMART commands also failed; the result is incomplete.\n'
            unknown_count=$((unknown_count + 1))
        fi
    elif (( (smart_status & 7) != 0 )); then
        printf '[UNKNOWN] Could not collect complete SMART data (smartctl status=%d).\n' "$smart_status"
        unknown_count=$((unknown_count + 1))
    elif grep -Eiq '^(SMART overall-health self-assessment test result:[[:space:]]*PASSED|SMART Health Status:[[:space:]]*OK)' "$tmp_output"; then
        printf '[PASS] No health failure reported by this SMART query.\n'
        pass_count=$((pass_count + 1))
    else
        printf '[UNKNOWN] No recognizable SMART health status was returned.\n'
        unknown_count=$((unknown_count + 1))
    fi

done

printf '\nSummary: %d PASS, %d WARN, %d UNKNOWN\n' "$pass_count" "$warning_count" "$unknown_count"
if (( warning_count > 0 )); then
    exit 1
fi
if (( unknown_count > 0 )); then
    exit 2
fi
exit 0
