#!/usr/bin/env bash
# DLGST Online Monitor installer. Safe to run on first install or as an update.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_XRAY="$REPO_ROOT/xray"
TARGET_BASE="${DLGST_PANEL_BASE:-/root/autoscriptxray}"
TARGET_XRAY="$TARGET_BASE/xray"
STAMP="$(date +%Y%m%d-%H%M%S)"
if [[ ${EUID} -ne 0 ]]; then echo "Jalankan sebagai root." >&2; exit 1; fi
required=(online-monitor-menu.sh client-monitor.sh online-monitor.sh activity-count.sh)
for f in "${required[@]}"; do [[ -f "$SOURCE_XRAY/$f" ]] || { echo "File sumber tidak ditemukan: $SOURCE_XRAY/$f" >&2; exit 1; }; done
[[ -d "$SOURCE_XRAY/monitor" ]] || { echo "Folder monitor tidak ditemukan." >&2; exit 1; }
mkdir -p "$TARGET_XRAY/monitor"
BACKUP="$TARGET_BASE/backup/online-monitor-$STAMP"; backup_needed=0
for f in "${required[@]}"; do [[ -f "$TARGET_XRAY/$f" && ! "$SOURCE_XRAY/$f" -ef "$TARGET_XRAY/$f" ]] && backup_needed=1; done
[[ -d "$TARGET_XRAY/monitor" ]] && [[ "$(find "$TARGET_XRAY/monitor" -maxdepth 1 -type f 2>/dev/null | wc -l)" -gt 0 ]] && backup_needed=1
if (( backup_needed )); then mkdir -p "$BACKUP"; for f in "${required[@]}"; do [[ -f "$TARGET_XRAY/$f" ]] && cp -a "$TARGET_XRAY/$f" "$BACKUP/"; done; cp -a "$TARGET_XRAY/monitor" "$BACKUP/" 2>/dev/null || true; fi
for f in "${required[@]}"; do if [[ "$SOURCE_XRAY/$f" != "$TARGET_XRAY/$f" ]]; then install -m 0755 "$SOURCE_XRAY/$f" "$TARGET_XRAY/$f"; else chmod 0755 "$TARGET_XRAY/$f"; fi; done
for f in "$SOURCE_XRAY"/monitor/*.sh; do [[ -f "$f" ]] || continue; if [[ "$f" != "$TARGET_XRAY/monitor/$(basename "$f")" ]]; then install -m 0755 "$f" "$TARGET_XRAY/monitor/$(basename "$f")"; else chmod 0755 "$f"; fi; done
for f in "${required[@]}" "$TARGET_XRAY"/monitor/*.sh; do bash -n "$TARGET_XRAY/$f"; done
echo "DLGST ONLINE MONITOR berhasil dipasang/diperbarui."
echo "Lokasi: $TARGET_XRAY"
if (( backup_needed )); then echo "Backup lama: $BACKUP"; else echo "Backup: tidak diperlukan."; fi
echo "Tidak mengubah akun, database, konfigurasi Xray/Nginx, atau me-restart service."
