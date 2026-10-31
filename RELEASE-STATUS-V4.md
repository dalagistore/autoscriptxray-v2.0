# DLGST XRAY PANEL V4 — Experimental Integration Build

This package integrates experimental transport modules into the first-run `setup.sh`. It is **not a production/stable release**.

Included module installers: XHTTP (VMess/VLESS/Trojan), HTTPUpgrade (VMess/VLESS/Trojan), VLESS REALITY TCP, mKCP UDP (VMess/VLESS/Trojan), Shadowsocks TCP/UDP inbound, and separate Hysteria 2 service.

Limitations: legacy add/renew/delete menus are not all wired to every new inbound; Shadowsocks native inbound starts with a placeholder password; Hysteria 2 uses one initial server password; REALITY and mKCP direct ports require firewall openings. Client link/QR generation is not complete for all new transports.

Test on a disposable Debian 12 KVM VPS. The installer backs up Xray and NGINX configs before modifying them and validates both configs before restarting. External VPS/provider firewall must be configured separately.
