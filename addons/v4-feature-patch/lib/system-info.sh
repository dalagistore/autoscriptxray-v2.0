#!/usr/bin/env bash
set -euo pipefail

_dl_domain() { [[ -r /etc/xray/domain ]] && cat /etc/xray/domain || hostname -f 2>/dev/null || hostname; }
_dl_bytes() { awk -v n="${1:-0}" 'BEGIN { split("B KiB MiB GiB TiB",u); i=1; while(n>=1024 && i<5){n/=1024;i++} printf "%.2f %s",n,u[i] }'; }

dlgst_system_info() {
  local ip isp os up cpu mem_total mem_used disk_total disk_used domain rx tx today yesterday
  ip=$(curl -4fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
  isp=$( (command -v whois >/dev/null && whois "$ip" 2>/dev/null | awk -F: 'tolower($1) ~ /orgname|org-name|org|isp/ {sub(/^ /,"",$2); print $2; exit}') || true )
  os=$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Unknown}")
  up=$(uptime -p 2>/dev/null | sed 's/^up //')
  cpu=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)/{gsub(/,/,".",$2); printf "%.0f%%",100-$2; exit}')
  read -r mem_total mem_used < <(free -m | awk '/Mem:/ {print $2,$3}')
  read -r disk_total disk_used < <(df -hP / | awk 'NR==2 {print $2,$3}')
  domain=$(_dl_domain)
  printf 'SYSTEM INFORMATION\n'
  printf 'IP VPS       : %s\nDOMAIN       : %s\nISP          : %s\nOS           : %s\nUPTIME       : %s\nCPU USAGE    : %s\nRAM USAGE    : %sMB / %sMB\nDISK USAGE   : %s / %s\nSERVER TIME  : %s\n' \
    "$ip" "$domain" "${isp:-Unknown}" "$os" "${up:-Unknown}" "${cpu:-Unknown}" "${mem_used:-0}" "${mem_total:-0}" "$disk_used" "$disk_total" "$(date '+%F %T %Z')"
}

dlgst_bandwidth() {
  local iface rx tx today yesterday
  iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1);exit}}')
  [[ -n "$iface" && -r "/sys/class/net/$iface/statistics/rx_bytes" ]] || { echo 'Bandwidth interface tidak ditemukan.'; return 0; }
  rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes"); tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
  printf 'INTERFACE    : %s\nRX TOTAL     : %s\nTX TOTAL     : %s\n' "$iface" "$(_dl_bytes "$rx")" "$(_dl_bytes "$tx")"
  echo 'Catatan: RX/TX di atas adalah counter sejak interface aktif, bukan pemakaian hari ini/kemarin.'
}
