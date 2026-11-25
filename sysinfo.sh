#!/usr/bin/env bash
set -euo pipefail

mode=${1-}
if (( $# > 1 )) || [[ -n $mode && $mode != --save && $mode != --cron-run ]]; then
    printf 'Usage: %s [--save]\n' "${0##*/}" >&2
    exit 2
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
timestamp=$(date '+%F %T %Z')
system_hostname=$(hostname)
current_user=$(whoami)

print_report() {
    printf 'Hostname: %s\n' "$system_hostname"
    printf 'Date and time: %s\n' "$timestamp"
    printf 'Logged-in user: %s\n' "$current_user"

    printf '\nDisk usage for /:\n'
    df -h /

    printf '\nMemory usage:\n'
    free -h

    printf '\nTop 5 processes by memory (RSS in KiB):\n'
    ps -eo pid,user,comm,%mem,rss --sort=-rss | awk 'NR <= 6'
}

install_hourly_cron() {
    if ! command -v crontab >/dev/null; then
        printf 'Cron setup requires crontab. Install and start cron, then rerun this script.\n' >&2
        return 1
    fi
    if [[ $repo_dir == *%* || $repo_dir == *$'\n'* || $repo_dir == *$'\r'* ]]; then
        printf 'Use a project path without percent signs or line breaks for cron.\n' >&2
        return 1
    fi

    local quoted_dir="'${repo_dir//\'/\'\\\'\'}'"
    local job="0 * * * * cd $quoted_dir && PATH=/usr/bin:/bin /bin/bash ./sysinfo.sh --cron-run >/dev/null 2>>cron.log # assignment-1-sysinfo"
    local legacy_job='0 * * * * cd "$HOME/devops-course/assignment-1-shell-git" && ./sysinfo.sh --save >/dev/null 2>>"$HOME/devops-course/assignment-1-shell-git/cron.log"'
    local current line

    if ! current=$(LC_ALL=C crontab -l 2>&1); then
        if [[ $current != 'no crontab for '* ]]; then
            printf '%s\n' "$current" >&2
            return 1
        fi
        current=
    fi

    # Migrate the old README example and replace entries created by the installer.
    {
        if [[ -n $current ]]; then
            while IFS= read -r line; do
                if [[ $line != "$legacy_job" && $line != *' # assignment-1-sysinfo' ]]; then
                    printf '%s\n' "$line"
                fi
            done <<< "$current"
        fi
        printf '%s\n' "$job"
    } | crontab -

    printf 'Cron job registered or replaced. It runs at the start of every hour.\n'
}

report_file="$repo_dir/sysinfo-${timestamp%% *}.txt"
temp_report=$(mktemp -- "$report_file.XXXXXX")
trap 'rm -f -- "$temp_report"' EXIT
print_report > "$temp_report"
mv -fT -- "$temp_report" "$report_file"
trap - EXIT

# Cron refreshes the report without updating the crontab.
if [[ $mode != --cron-run ]]; then
    cat -- "$report_file"
    printf '\nSaved report to %s\n' "$report_file"
    install_hourly_cron
fi
