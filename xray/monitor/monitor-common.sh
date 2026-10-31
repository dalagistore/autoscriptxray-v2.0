#!/usr/bin/env bash
# Shared helpers for DLGST Online Monitor.
MONITOR_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
XRAY_DIR="$(cd -- "$MONITOR_DIR/.." && pwd)"
CONFIG_FILE="${DLGST_XRAY_CONFIG:-/etc/xray/config.json}"
XRAY_ACCESS_LOG="${DLGST_XRAY_ACCESS_LOG:-/var/log/xray/access.log}"
MONITOR_WINDOW="${DLGST_MONITOR_WINDOW:-600}"

mon_header() {
    printf '\n%-20s %-13s %-14s %-18s %-12s\n' 'USERNAME' 'PROTOCOL' 'TRANSPORT' 'IP ADDRESS' 'STATUS'
    printf '%s\n' '--------------------------------------------------------------------------------'
}
mon_service_state() {
    systemctl is-active --quiet "$1" 2>/dev/null
}
mon_pause() {
    [[ -t 0 ]] && read -r -p 'Tekan Enter untuk kembali...' _ || true
}
