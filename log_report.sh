#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

if (( $# != 1 )); then
    printf 'Usage: %s <access-log-file>\n' "${0##*/}" >&2
    exit 2
fi

log_file=$1
if [[ ! -f $log_file || ! -r $log_file ]]; then
    printf 'Error: cannot read log file: %s\n' "$log_file" >&2
    exit 1
fi

awk '
    {
        response = $0
        # Remove the log prefix and quoted request to reach the status field.
        if (!sub(/^[[:space:]]*[^[:space:]"]+[[:space:]]+[^"]*"([^"\\]|\\.)*"[[:space:]]+/, "", response)) {
            next
        }
        if (response !~ /^[0-9][0-9][0-9]([[:space:]]|$)/) {
            next
        }
        requests++
        if (substr(response, 1, 3) == "404") {
            errors++
        }
        hits[$1]++
    }
    END {
        printf "Total requests: %d\n", requests
        printf "404 errors: %d\n", errors
        for (ip in hits) {
            printf "%d %s\n", hits[ip], ip
        }
    }
' < "$log_file" | {
    IFS= read -r total_line
    IFS= read -r error_line
    printf '%s\n' "$total_line" "$error_line" 'Top 3 IP addresses (IP, requests):'
    sort -k1,1nr -k2,2 | awk '
        NR <= 3 { printf "  %s %s\n", $2, $1 }
        END { if (NR == 0) print "  (none)" }
    '
}
