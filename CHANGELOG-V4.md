# Changelog — V4 integration candidate

- Retained the supplied AutoscriptXRAY source tree and existing account scripts.
- Kept `setup.sh` as the single installation entry point.
- Integrated V4 utility installation into the main setup flow.
- Added explicit release-scope and validation documentation.
- Did not advertise unimplemented transports/protocols as functional.

- Beta transport integration: XHTTP, HTTPUpgrade, VLESS REALITY TCP, mKCP, Shadowsocks TCP/UDP inbound, separate Hysteria 2 service.
- Added low-level `dlgst-account` command for new Xray inbound client lists.
- Main setup invokes V4 integration automatically after base Xray install.
- Experimental; account menu and client-link/QR integration remain incomplete.
