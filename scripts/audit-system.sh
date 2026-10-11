#!/usr/bin/env bash

# Read-only summary of the running Linux system.
# Deliberately avoids hostnames, usernames, MAC addresses and serial numbers.

print_section() {
    printf '\n== %s ==\n' "$1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section "Operating system"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf 'Distribution: %s\n' "${PRETTY_NAME:-unknown}"
else
    printf 'Distribution: unknown\n'
fi

printf 'Kernel: %s\n' "$(uname -r)"
printf 'Architecture: %s\n' "$(uname -m)"

if command_exists systemd; then
    printf 'systemd: %s\n' "$(systemd --version | head -n1)"
else
    printf 'systemd: not detected\n'
fi

print_section "Desktop"
printf 'XDG current desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'Desktop session: %s\n' "${DESKTOP_SESSION:-unknown}"
printf 'Session type: %s\n' "${XDG_SESSION_TYPE:-unknown}"

print_section "CPU and memory"
if command_exists lscpu; then
    lscpu | awk -F: '
        /Model name/ {gsub(/^[[:space:]]+/, "", $2); print "CPU: " $2}
        /^CPU\(s\)/ {gsub(/^[[:space:]]+/, "", $2); print "Logical CPUs: " $2; exit}
    '
fi

if command_exists free; then
    free -h | awk '/^Mem:/ {print "Memory: " $2}'
fi

print_section "Root filesystem"
if command_exists findmnt; then
    findmnt -no SOURCE,FSTYPE,OPTIONS /
fi

print_section "Package managers"
for manager in apt dnf pacman zypper apk flatpak snap; do
    if command_exists "$manager"; then
        printf '%s: available\n' "$manager"
    fi
done

print_section "Network management"
for service in NetworkManager systemd-networkd; do
    if command_exists systemctl && systemctl is-active --quiet "$service" 2>/dev/null; then
        printf '%s: active\n' "$service"
    fi
done
