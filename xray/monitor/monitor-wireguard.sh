#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/monitor-common.sh"
printf '%-20s %-13s %-14s %-18s %-12s\n' PEER PROTOCOL TRANSPORT ENDPOINT STATUS
printf '%s\n' '--------------------------------------------------------------------------------'
if ! command -v wg >/dev/null 2>&1 || ! wg show wg0 >/dev/null 2>&1; then
    echo 'Interface wg0 atau perintah wg tidak tersedia.'; exit 0
fi
now=$(date +%s)
wg show wg0 dump | tail -n +2 | while IFS=$'\t' read -r pub psk endpoint allowed latest rx tx keepalive; do
    [[ -n "$pub" ]] || continue
    if [[ "$latest" =~ ^[0-9]+$ ]] && (( latest > 0 )); then
        age=$((now-latest))
        if (( age <= 180 )); then status='RECENT-HANDSHAKE'
        else status='ACTIVITY'; fi
    else status='OFFLINE'; fi
    printf '%-20s %-13s %-14s %-18s %-12s\n' "${pub:0:16}" WIREGUARD UDP "${endpoint:--}" "$status"
done
echo 'Catatan: handshake baru menunjukkan komunikasi baru-baru ini, bukan bukti sesi aktif terus-menerus.'
