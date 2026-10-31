#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Jalankan sebagai root: bash install-patch.sh'; exit 1; }
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BASE=/usr/local/lib/dlgst-v4
BIN=/usr/local/bin
mkdir -p "$BASE" "$BIN"
install -m 0644 "$SCRIPT_DIR/lib/system-info.sh" "$BASE/system-info.sh"
install -m 0755 "$SCRIPT_DIR/bin/dlgst-system-info" "$BIN/dlgst-system-info"
install -m 0755 "$SCRIPT_DIR/bin/dlgst-account-show" "$BIN/dlgst-account-show"
install -m 0755 "$SCRIPT_DIR/bin/dlgst-udp-audit" "$BIN/dlgst-udp-audit"
command -v jq >/dev/null || echo 'PERINGATAN: jq belum terpasang (apt install jq)'
echo 'DLGST V4 Feature Patch installed.'
echo 'Commands: dlgst-system-info [all|info|bandwidth]'
echo '          dlgst-account-show <protocol> <username>'
echo '          dlgst-udp-audit'
