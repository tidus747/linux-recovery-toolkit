#!/usr/bin/env bash

# Summarise top-level HOME disk usage.
# WARNING: directory names can contain personal information.
# Output should be treated as private unless manually sanitised.

home_dir=${HOME:-}

if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
    printf 'Unable to determine a valid HOME directory.\n' >&2
    exit 1
fi

printf 'HOME usage summary\n'
printf '==================\n'
printf 'Path: <current-user-home>\n\n'

du -h --max-depth=1 "$home_dir" 2>/dev/null |
    sed "s#^$home_dir#<HOME>#" |
    sort -h
