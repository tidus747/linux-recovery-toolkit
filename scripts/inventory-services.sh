#!/usr/bin/env bash

# Read-only inventory of enabled systemd services and timers.

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section() {
    printf '\n== %s ==\n' "$1"
}

if ! command_exists systemctl; then
    printf 'systemctl was not found. This script currently supports systemd systems.\n' >&2
    exit 1
fi

print_section "Enabled system services"
systemctl list-unit-files     --type=service     --state=enabled     --no-legend     --no-pager 2>/dev/null || true

print_section "Enabled system timers"
systemctl list-unit-files     --type=timer     --state=enabled     --no-legend     --no-pager 2>/dev/null || true

if systemctl --user show-environment >/dev/null 2>&1; then
    print_section "Enabled user services"
    systemctl --user list-unit-files         --type=service         --state=enabled         --no-legend         --no-pager 2>/dev/null || true

    print_section "Enabled user timers"
    systemctl --user list-unit-files         --type=timer         --state=enabled         --no-legend         --no-pager 2>/dev/null || true
else
    print_section "User systemd manager"
    printf 'No accessible user systemd manager in this session.\n'
fi
