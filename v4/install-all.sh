#!/usr/bin/env bash
set -Eeuo pipefail
DIR=$(cd -- "$(dirname -- "$0")" && pwd)
"$DIR/install-transports.sh"
"$DIR/install-hysteria2.sh"
install -m 755 "$DIR/bin/dlgst-account" /usr/local/bin/dlgst-account
