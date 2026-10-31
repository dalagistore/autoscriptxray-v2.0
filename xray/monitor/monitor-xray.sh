#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=monitor-common.sh
source "$HERE/monitor-common.sh"

python3 - "$CONFIG_FILE" "$XRAY_ACCESS_LOG" "$MONITOR_WINDOW" <<'PY'
import sys, json, re, os
from datetime import datetime, timedelta

cfg_path, log_path, window = sys.argv[1], sys.argv[2], int(sys.argv[3])
if not os.path.isfile(cfg_path):
    print(f"Xray config tidak ditemukan: {cfg_path}")
    raise SystemExit(0)
try:
    with open(cfg_path, encoding='utf-8') as f:
        cfg = json.load(f)
except Exception as exc:
    print(f"Gagal membaca JSON Xray: {exc}")
    raise SystemExit(0)

transport_names = {
    'raw':'RAW/TCP', 'tcp':'RAW/TCP', 'ws':'WS', 'grpc':'GRPC',
    'httpupgrade':'HTTP-UPGRADE', 'xhttp':'XHTTP', 'kcp':'MKCP',
    'http':'HTTP', 'domainsocket':'DOMAIN-SOCKET'
}
inbounds = {}
for item in cfg.get('inbounds', []):
    tag = item.get('tag') or '-'
    protocol = str(item.get('protocol') or 'UNKNOWN').upper()
    stream = item.get('streamSettings') or {}
    network = str(stream.get('network') or 'raw').lower()
    inbounds[tag] = (protocol, transport_names.get(network, network.upper()))

if not os.path.isfile(log_path):
    print(f"Xray access log tidak ditemukan: {log_path}")
    raise SystemExit(0)
now = datetime.now()
cutoff = now - timedelta(seconds=window)
latest = {}
# Read current and rotated plain logs where available; compressed archives intentionally skipped.
paths = [log_path, log_path + '.1']
for path in paths:
    if not os.path.isfile(path):
        continue
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            lines = f.readlines()[-100000:]
    except OSError:
        continue
    for line in lines:
        if 'accepted' not in line or 'email:' not in line:
            continue
        tm = re.match(r'(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})', line)
        tag = re.search(r'\[([^\]]+)\s*>>', line)
        user = re.search(r'email:\s*(\S+)', line)
        if not (tm and tag and user):
            continue
        try:
            event = datetime.strptime(tm.group(1), '%Y/%m/%d %H:%M:%S')
        except ValueError:
            continue
        if not cutoff <= event <= now:
            continue
        inbound_tag, username = tag.group(1).strip(), user.group(1).strip()
        proto, transport = inbounds.get(inbound_tag, ('XRAY', 'UNKNOWN'))
        key = (username, proto, transport, inbound_tag)
        if key not in latest or event > latest[key]:
            latest[key] = event

if not latest:
    print(f"Tidak ada aktivitas Xray dalam {window // 60} menit terakhir.")
else:
    for (username, proto, transport, tag), event in sorted(latest.items(), key=lambda x:x[1], reverse=True):
        # Xray behind reverse proxy logs 127.0.0.1; never report that as customer IP.
        print(f"{username[:19]:<20} {proto:<13} {transport:<14} {'UNKNOWN':<18} {'ACTIVITY':<12} [{tag}]")
print('Catatan: access log membuktikan aktivitas, bukan sesi TCP/VPN yang masih aktif.')
print('IP pelanggan tidak diklaim karena Xray berada di belakang reverse proxy.')
PY
