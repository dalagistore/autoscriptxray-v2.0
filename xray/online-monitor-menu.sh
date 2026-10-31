#!/usr/bin/env bash
BASE="${DLGST_PANEL_BASE:-/root/autoscriptxray}"
XRAY="$BASE/xray"
MON="$XRAY/monitor"
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; WHITE='\033[1;37m'; NC='\033[0m'
header(){ clear 2>/dev/null || true; echo -e "${CYAN}╭──────────────────────────────────────────────╮${NC}"; echo -e "${CYAN}│${WHITE}             DLGST ONLINE MONITOR             ${CYAN}│${NC}"; echo -e "${CYAN}│${WHITE}              PREMIUM VPN PANEL               ${CYAN}│${NC}"; echo -e "${CYAN}╰──────────────────────────────────────────────╯${NC}"; }
pause(){ echo; read -r -p 'Tekan Enter untuk kembali...' _ || true; }
run_module(){ local file="$1"; header; if [[ -f "$MON/$file" ]]; then bash "$MON/$file"; else echo -e "${RED}Modul tidak ditemukan: $MON/$file${NC}"; fi; pause; }
service_status(){ if systemctl is-active --quiet "$2" 2>/dev/null; then printf '%-17s %b\n' "$1" "${GREEN}RUNNING${NC}"; else printf '%-17s %b\n' "$1" "${RED}STOPPED${NC}"; fi; }
while true; do
 header
 echo -e "${WHITE}[1] ALL MONITOR          [2] CLIENT MONITOR${NC}"
 echo -e "${WHITE}[3] SSH                  [4] VMESS${NC}"
 echo -e "${WHITE}[5] VLESS                [6] TROJAN${NC}"
 echo -e "${WHITE}[7] SHADOWSOCKS          [8] WIREGUARD${NC}"
 echo -e "${WHITE}[9] ZIVPN                [10] UDP CUSTOM${NC}"
 echo -e "${WHITE}[0] BACK${NC}"
 read -r -p 'Pilih menu : ' choice
 case "$choice" in
  1) header; echo 'ALL SERVICE STATUS'; service_status SSH ssh; service_status DROPBEAR dropbear; service_status XRAY xray; service_status NGINX nginx; service_status WIREGUARD wg-quick@wg0; service_status ZIVPN zivpn; service_status 'UDP CUSTOM' udp-custom; echo; if [[ -x "$XRAY/activity-count.sh" ]]; then printf 'Akun Xray dengan aktivitas 10 menit terakhir: '; "$XRAY/activity-count.sh"; fi; pause ;;
  2) bash "$XRAY/online-monitor.sh" ;;
  3) run_module monitor-ssh.sh ;;
  4) [[ -f "$XRAY/cek-vmess.sh" ]] && bash "$XRAY/cek-vmess.sh" || run_module monitor-xray.sh ;;
  5) [[ -f "$XRAY/cek-vless.sh" ]] && bash "$XRAY/cek-vless.sh" || run_module monitor-xray.sh ;;
  6) [[ -f "$XRAY/cek-trojan.sh" ]] && bash "$XRAY/cek-trojan.sh" || run_module monitor-xray.sh ;;
  7) [[ -f "$XRAY/cek-ssws.sh" ]] && bash "$XRAY/cek-ssws.sh" || run_module monitor-xray.sh ;;
  8) run_module monitor-wireguard.sh ;;
  9) run_module monitor-zivpn.sh ;;
  10) run_module monitor-udp-custom.sh ;;
  0|x|X) exit 0 ;;
  *) echo 'Pilihan tidak valid.'; sleep 1 ;;
 esac
done
