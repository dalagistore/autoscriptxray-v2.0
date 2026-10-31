#!/usr/bin/env bash
set -u
if ! systemctl is-active --quiet udp-custom 2>/dev/null; then
    echo 'UDP-Custom service: STOPPED'; exit 0
fi
echo 'UDP-Custom service: RUNNING'
python3 - <<'PY'
import subprocess, re, sys
from datetime import datetime, timezone

# Journal short-iso timestamps preserve ordering and allow service-start filtering.
start = subprocess.run(['systemctl','show','udp-custom','-p','ActiveEnterTimestamp','--value'], capture_output=True, text=True).stdout.strip()
start_dt = None
if start and start != 'n/a':
    for fmt in ('%a %Y-%m-%d %H:%M:%S %Z', '%a %Y-%m-%d %H:%M:%S %Z'):
        try:
            start_dt = datetime.strptime(start, fmt).astimezone()
            break
        except ValueError: pass
cmd = ['journalctl','-u','udp-custom','--since','7 days ago','-o','short-iso','--no-pager']
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode not in (0,):
    print('Tidak dapat membaca journal UDP-Custom:', r.stderr.strip() or r.returncode); sys.exit(0)
by_src = {}
for line in r.stdout.splitlines():
    # journal prefix: YYYY-MM-DDTHH:MM:SS[.usec]+TZ hostname ...
    tm = re.match(r'^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:[+-]\d\d:\d\d|Z)?)', line)
    if tm and start_dt:
        try:
            stamp = datetime.fromisoformat(tm.group(1).replace('Z','+00:00')).astimezone()
            if stamp < start_dt: continue
        except ValueError: pass
    src = re.search(r'\[src:([^\]]+)\]', line)
    user = re.search(r'\[user:([^\]]+)\]', line)
    if not src: continue
    endpoint = src.group(1)
    if 'Client connected' in line and user:
        by_src[endpoint] = user.group(1)
    elif 'Client disconnected' in line:
        by_src.pop(endpoint, None)
print(f"{'USERNAME':<20} {'PROTOCOL':<13} {'TRANSPORT':<14} {'IP ADDRESS':<18} {'STATUS':<12}")
print('-' * 82)
if not by_src:
    print('Tidak ada sesi tersambung yang tercatat dalam journal.')
else:
    for endpoint, username in by_src.items():
        host = endpoint.rsplit(':',1)[0]
        if host.startswith('[') and host.endswith(']'): host = host[1:-1]
        print(f'{username[:19]:<20} UDP-CUSTOM    UDP            {host[:17]:<18} ONLINE')
print('Sumber: journalctl UDP-Custom. Akurasi bergantung pada kelengkapan log connect/disconnect.')
PY
