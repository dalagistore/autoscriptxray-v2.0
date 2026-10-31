#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/monitor-common.sh"
printf '%-20s %-13s %-14s %-18s %-12s\n' USERNAME PROTOCOL TRANSPORT IP STATUS
printf '%s\n' '--------------------------------------------------------------------------------'
if ! command -v who >/dev/null 2>&1; then echo 'Perintah who tidak tersedia.'; exit 0; fi
found=0
while read -r user tty _ _ origin; do
    [[ -n "${user:-}" ]] || continue
    found=1
    ip="${origin#(}"; ip="${ip%)}"; [[ "$ip" == "$origin" ]] && ip='UNKNOWN'
    if [[ "$user" == root ]]; then status='ADMIN'; shown='root (ADMIN)'
    else status='LOGIN'; shown="$user"; fi
    printf '%-20s %-13s %-14s %-18s %-12s\n' "$shown" SSH TCP "$ip" "$status"
done < <(who 2>/dev/null)
(( found )) || echo 'Tidak ada sesi login interaktif (who).'
echo
echo 'Koneksi TCP SSH/Dropbear established (endpoint):'
if command -v ss >/dev/null 2>&1; then
    ss -Htnp state established 2>/dev/null | awk '/sshd|dropbear/ {print "  " $5 " -> " $4}' | sort -u
else
    echo '  Perintah ss tidak tersedia.'
fi
echo 'Catatan: sesi root ditandai ADMIN dan tidak dihitung sebagai pelanggan.'
