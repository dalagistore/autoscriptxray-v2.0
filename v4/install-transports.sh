#!/usr/bin/env bash
# Safe additive transport installer for DLGST XRAY PANEL.
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Jalankan sebagai root."; exit 1; }
XRAY=/etc/xray/config.json
NGINX=/etc/nginx/conf.d/xray.conf
command -v jq >/dev/null || { apt-get update && apt-get install -y jq; }
command -v python3 >/dev/null || { apt-get update && apt-get install -y python3; }
command -v xray >/dev/null || { echo "Binary xray tidak ditemukan."; exit 1; }
[[ -s "$XRAY" && -s "$NGINX" ]] || { echo "Config Xray/Nginx tidak ditemukan."; exit 1; }
jq -e '.inbounds|type=="array"' "$XRAY" >/dev/null || { echo "config.json tidak valid."; exit 1; }

TS=$(date +%Y%m%d-%H%M%S)
BACK="/etc/dlgst/backups/transport-$TS"
install -d -m 700 "$BACK"
cp -a "$XRAY" "$BACK/config.json"
cp -a "$NGINX" "$BACK/xray.conf"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Add only missing XHTTP/HTTPUpgrade/REALITY/mKCP inbounds.
# Existing ports/tags are preserved; port collisions abort before changing live files.
python3 - "$XRAY" "$TMP/config.json" <<'PY'
import json,sys
src,dst=sys.argv[1:]
d=json.load(open(src))
ins=d.setdefault("inbounds",[])
tags={x.get("tag") for x in ins}
ports={x.get("port") for x in ins}
new=[
("vmess-xhttp","vmess",34101,"xhttp","/vmess-xhttp"),
("vless-xhttp","vless",34102,"xhttp","/vless-xhttp"),
("trojan-xhttp","trojan",34103,"xhttp","/trojan-xhttp"),
("vmess-httpupgrade","vmess",34111,"httpupgrade","/vmess-hu"),
("vless-httpupgrade","vless",34112,"httpupgrade","/vless-hu"),
("trojan-httpupgrade","trojan",34113,"httpupgrade","/trojan-hu"),
("vmess-mkcp-udp","vmess",34121,"mkcp",""),
("vless-mkcp-udp","vless",34122,"mkcp",""),
("trojan-mkcp-udp","trojan",34123,"mkcp",""),
]
for tag,proto,port,net,path in new:
    if tag in tags: continue
    if port in ports: raise SystemExit(f"Port {port} sudah dipakai inbound lain; batal.")
    settings={"clients":[]}
    if proto=="vless": settings["decryption"]="none"
    stream={"network":"kcp" if net=="mkcp" else net,"security":"none"}
    if net=="xhttp": stream["xhttpSettings"]={"path":path,"mode":"auto"}
    elif net=="httpupgrade": stream["httpupgradeSettings"]={"path":path}
    elif net=="mkcp": stream["kcpSettings"]={"seed":"dlgst"}
    ins.append({"listen":"0.0.0.0" if net=="mkcp" else "127.0.0.1","port":port,"protocol":proto,"tag":tag,"settings":settings,"streamSettings":stream})
    tags.add(tag); ports.add(port)
# REALITY VLESS TCP, only if absent.
# REALITY is deliberately left untouched; it needs a separately validated key/SNI workflow.
json.dump(d,open(dst,"w"),indent=2)
PY

# Route XHTTP and HTTPUpgrade only into existing port-443 server block.
python3 - "$NGINX" "$TMP/xray.conf" <<'PY'
import sys,re
src,dst=sys.argv[1:]
s=open(src).read()
if "DLGST-TRANSPORT-ROUTES" in s:
    open(dst,"w").write(s); raise SystemExit(0)
# Locate server blocks by brace depth and identify the block listening on 443.
blocks=[]
for m in re.finditer(r'\bserver\s*\{',s):
    start=m.start(); depth=0; quote=None; esc=False; end=None
    for i in range(s.find("{",m.start()),len(s)):
        c=s[i]
        if quote:
            if esc: esc=False
            elif c=="\\": esc=True
            elif c==quote: quote=None
            continue
        if c in "'\\"": quote=c; continue
        if c=="{": depth+=1
        elif c=="}":
            depth-=1
            if depth==0: end=i; break
    if end is not None:
        b=s[start:end+1]
        if re.search(r'listen\s+(?:\[::\]:)?443\b',b): blocks.append((start,end,b))
if len(blocks)!=1: raise SystemExit(f"Harus ditemukan tepat satu server TLS 443, ditemukan {len(blocks)}. Nginx tidak diubah.")
start,end,b=blocks[0]
routes=[]
for path,port,kind in [
("vmess-xhttp",34101,"http"),("vless-xhttp",34102,"http"),("trojan-xhttp",34103,"http"),
("vmess-hu",34111,"http"),("vless-hu",34112,"http"),("trojan-hu",34113,"http")]:
    if re.search(r'location\s+(?:\^~\s+)?/'+re.escape(path)+r'\b',b): continue
    routes.append(f"""
    location = /{path} {{
        proxy_pass http://127.0.0.1:{port};
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
    }}
""")
if routes:
    b=b[:-1]+"\n    # DLGST-TRANSPORT-ROUTES: generated, additive\n"+"".join(routes)+"}\n"
    s=s[:start]+b+s[end+1:]
open(dst,"w").write(s)
PY

# Validate candidate config before installing it.
xray run -test -config "$TMP/config.json" >/dev/null
install -m 600 "$TMP/config.json" "$XRAY.new"
install -m 644 "$TMP/xray.conf" "$NGINX.new"
mv "$XRAY.new" "$XRAY"
mv "$NGINX.new" "$NGINX"
rollback() {
  cp -a "$BACK/config.json" "$XRAY"
  cp -a "$BACK/xray.conf" "$NGINX"
  systemctl restart xray || true
  systemctl reload nginx || true
}
if ! nginx -t; then rollback; echo "Nginx gagal; konfigurasi dipulihkan."; exit 1; fi
if ! xray run -test -config "$XRAY" >/dev/null; then rollback; echo "Xray gagal; konfigurasi dipulihkan."; exit 1; fi
if ! systemctl restart xray || ! systemctl is-active --quiet xray; then rollback; echo "Xray gagal aktif; rollback dilakukan."; exit 1; fi
if ! systemctl reload nginx; then rollback; echo "Nginx gagal reload; rollback dilakukan."; exit 1; fi
echo "Transport tambahan terpasang: XHTTP, HTTP Upgrade, dan mKCP untuk VMESS/VLESS/TROJAN."
echo "Backup: $BACK"
echo "Catatan: REALITY dan Shadowsocks UDP tidak diaktifkan otomatis pada tahap ini agar tidak merusak konfigurasi/account database."
echo "Buka port UDP 34121-34123 pada firewall/provider bila mKCP digunakan."
