#!/usr/bin/env bash

# Read-only package inventory for rebuilding a Linux installation.
# Output is intended to be stored in a private local report.

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
    printf '%s\n' "${PRETTY_NAME:-unknown}"
else
    printf 'unknown\n'
fi

if command_exists apt-mark; then
    print_section "APT manually installed packages"
    apt-mark showmanual | LC_ALL=C sort
elif command_exists dpkg-query; then
    print_section "dpkg packages"
    dpkg-query -W -f='${binary:Package}\t${Version}\n' | LC_ALL=C sort
fi

if command_exists flatpak; then
    print_section "Flatpak applications"
    flatpak list --app --columns=application,origin 2>/dev/null | LC_ALL=C sort
fi

if command_exists snap; then
    print_section "Snap packages"
    snap list 2>/dev/null || true
fi

if command_exists pipx; then
    print_section "pipx applications"
    pipx list --short 2>/dev/null || true
fi

if command_exists npm; then
    print_section "npm global packages"
    npm --global list --depth=0 --parseable 2>/dev/null |
        sed '1d' |
        sed 's#.*/node_modules/##' |
        LC_ALL=C sort
fi

if command_exists cargo; then
    print_section "Cargo installed packages"
    cargo install --list 2>/dev/null |
        awk '/^[^[:space:]].*:$/ {sub(/:$/, ""); print}' |
        LC_ALL=C sort
fi
