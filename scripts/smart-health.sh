#!/usr/bin/env bash

# Focused, read-only SMART report.
# Disk serial numbers and WWNs are not requested or printed.

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists smartctl; then
    printf 'smartctl was not found. Install the smartmontools package first.\n' >&2
    exit 1
fi

if ! command_exists lsblk; then
    printf 'lsblk was not found.\n' >&2
    exit 1
fi

if (( $# > 0 )); then
    devices=("$@")
else
    mapfile -t devices < <(lsblk -dn -p -o NAME,TYPE | awk '$2 == "disk" {print $1}')
fi

if (( ${#devices[@]} == 0 )); then
    printf 'No block devices were found.\n' >&2
    exit 1
fi

for device in "${devices[@]}"; do
    if [[ ! -b "$device" ]]; then
        printf 'Skipping %s: not a block device.\n' "$device" >&2
        continue
    fi

    printf '\n== %s ==\n' "$device"
    lsblk -dn -o SIZE,MODEL,TRAN,ROTA "$device" 2>/dev/null |
        awk '{print "Device: " $0}'

    # Some devices require root access for SMART data. sudo is used only
    # for this read-only smartctl invocation.
    sudo smartctl -H -A -l selftest "$device" 2>/dev/null |
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
        '
done
