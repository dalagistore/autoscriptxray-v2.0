# Static validation report

This release archive is checked locally for ZIP integrity, Bash syntax, and JSON syntax. These checks do not validate systemd startup, firewall behavior, TLS issuance, DNS, protocol interoperability, client connectivity, throughput, or reboot persistence.

Run the following on a disposable Debian 12 VPS after upload:

```bash
find . -type f -name '*.sh' -print0 | while IFS= read -r -d '' f; do bash -n "$f" || exit 1; done
find config -type f -name '*.json' -print0 | while IFS= read -r -d '' f; do jq empty "$f" || exit 1; done
systemctl --failed
systemctl status xray nginx --no-pager
```

Only mark a feature stable after testing account create/renew/delete, client connection, UDP traffic where applicable, and reboot persistence.
