# Fresh install – Debian 12

```bash
apt update && apt install -y git ca-certificates
git clone https://github.com/USERNAME/REPOSITORY.git /root/dlgst-xray-panel
cd /root/dlgst-xray-panel
bash setup.sh
```

`setup.sh` is the only entry-point installer. It installs the V4 utility add-on automatically; manual execution of `addons/v4-feature-patch/install-patch.sh` is not needed. It intentionally stops if `/root/autoscriptxray` already exists to protect existing data.
