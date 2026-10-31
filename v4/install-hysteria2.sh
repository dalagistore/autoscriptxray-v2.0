#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
apt-get update; apt-get install -y curl jq
ARCH=$(dpkg --print-architecture); case "$ARCH" in amd64) A=amd64;; arm64) A=arm64;; *) echo "Unsupported architecture: $ARCH"; exit 1;; esac
URL=$(curl -fsSL https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r --arg a "$A" '.assets[] | select(.name|test("linux-"+$a+"\\.tar\\.gz$")) | .browser_download_url' | head -n1)
[[ -n "$URL" && "$URL" != null ]] || { echo 'Could not find Hysteria 2 release asset'; exit 1; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fL "$URL" -o "$TMP/hysteria.tgz"; tar -xzf "$TMP/hysteria.tgz" -C "$TMP"
BIN=$(find "$TMP" -type f -name hysteria -perm -111 | head -n1); [[ -n "$BIN" ]] || { echo 'Hysteria binary missing in release archive'; exit 1; }
install -m 755 "$BIN" /usr/local/bin/hysteria
install -d -m 700 /etc/hysteria
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || true)
[[ -n "$DOMAIN" && -s /etc/xray/cert.crt && -s /etc/xray/private.key ]] || { echo 'Need domain and /etc/xray TLS certificate first'; exit 1; }
if [[ ! -s /etc/hysteria/config.yaml ]]; then
  PASS=$(openssl rand -hex 16)
  cat > /etc/hysteria/config.yaml <<EOF
listen: :4443
tls:
  cert: /etc/xray/cert.crt
  key: /etc/xray/private.key
auth:
  type: password
  password: "$PASS"
masquerade:
  type: proxy
  proxy:
    url: https://www.microsoft.com
    rewriteHost: true
EOF
  chmod 600 /etc/hysteria/config.yaml
  echo "Hysteria 2 initial password: $PASS (save it securely)" > /root/hysteria2-credentials.txt
  chmod 600 /root/hysteria2-credentials.txt
fi
cat > /etc/systemd/system/hysteria-server.service <<'EOF'
[Unit]
Description=Hysteria 2 Server
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure
User=root
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload; systemctl enable --now hysteria-server
systemctl --no-pager --full status hysteria-server || true
echo 'Hysteria 2 installed. Open UDP 4443 in OS/provider firewall.'
