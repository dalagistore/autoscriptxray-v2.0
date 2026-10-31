#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/monitor/monitor-common.sh"
clear 2>/dev/null || true
printf '\033[1;36m%s\033[0m\n' '╔════════════════════════════════════════════════════════════════════╗' '║                       DLGST ONLINE MONITOR                        ║' '╚════════════════════════════════════════════════════════════════════╝'
echo "Waktu pemeriksaan : $(date '+%d-%m-%Y %H:%M:%S %Z')"
echo "Jendela aktivitas : $((MONITOR_WINDOW / 60)) menit terakhir"
echo
mon_header
bash "$HERE/monitor/monitor-xray.sh"
echo
printf '\033[1;36m%s\033[0m\n' '--- SSH ---'
bash "$HERE/monitor/monitor-ssh.sh"
echo
printf '\033[1;36m%s\033[0m\n' '--- WIREGUARD ---'
bash "$HERE/monitor/monitor-wireguard.sh"
echo
printf '\033[1;36m%s\033[0m\n' '--- ZIVPN ---'
bash "$HERE/monitor/monitor-zivpn.sh"
echo
printf '\033[1;36m%s\033[0m\n' '--- UDP-CUSTOM ---'
bash "$HERE/monitor/monitor-udp-custom.sh"
echo
echo 'STATUS:'
echo 'ONLINE    = sesi yang sumber datanya dapat membuktikan sesi tersambung.'
echo 'ACTIVITY  = event koneksi baru di log; bukan bukti sesi masih aktif.'
echo 'RECENT-HANDSHAKE = WireGuard memiliki handshake dalam 180 detik terakhir.'
echo 'ADMIN     = sesi administrator; tidak dihitung sebagai pelanggan.'
echo 'UNKNOWN   = telemetry pengguna belum tersedia.'
echo
read -r -p 'Tekan Enter untuk kembali...' _ || true
