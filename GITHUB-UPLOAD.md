# GitHub upload

Upload the complete contents of this directory to the repository root (not the containing folder). Commit as `DLGST XRAY PANEL V4 beta2 - integrated setup utilities`.

Fresh VPS command after upload:

```bash
apt update && apt install -y git ca-certificates
git clone https://github.com/USERNAME/REPOSITORY.git /root/dlgst-xray-panel
cd /root/dlgst-xray-panel
bash setup.sh
```

Do not publish secrets, private keys, account databases, or live configs.
