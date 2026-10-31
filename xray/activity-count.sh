#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${DLGST_XRAY_CONFIG:-/etc/xray/config.json}"
LOG="${DLGST_XRAY_ACCESS_LOG:-/var/log/xray/access.log}"
WINDOW="${DLGST_MONITOR_WINDOW:-600}"
python3 - "$CONFIG" "$LOG" "$WINDOW" <<'PY'
import sys, os, json, re
from datetime import datetime, timedelta
cfgp, logp, window = sys.argv[1], sys.argv[2], int(sys.argv[3])
try:
    with open(cfgp) as f: cfg=json.load(f)
except Exception:
    print(0); raise SystemExit
valid={i.get('tag') for i in cfg.get('inbounds',[]) if i.get('tag')}
cutoff=datetime.now()-timedelta(seconds=window); now=datetime.now(); users=set()
if os.path.isfile(logp):
    with open(logp, errors='replace') as f:
        for line in f:
            if 'accepted' not in line: continue
            tm=re.match(r'(\d{4}/\d\d/\d\d \d\d:\d\d:\d\d)',line)
            tag=re.search(r'\[([^\]]+)\s*>>',line); user=re.search(r'email:\s*(\S+)',line)
            if not (tm and tag and user and tag.group(1).strip() in valid): continue
            try: dt=datetime.strptime(tm.group(1),'%Y/%m/%d %H:%M:%S')
            except ValueError: continue
            if cutoff <= dt <= now: users.add(user.group(1))
print(len(users))
PY
