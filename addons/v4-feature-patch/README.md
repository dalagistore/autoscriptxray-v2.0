# DLGST XRAY PANEL V4 – Feature Patch (Add-on)

Patch add-on yang aman untuk instalasi Debian 12. Tidak mengubah `/etc/xray/config.json`, database akun, NGINX, firewall, atau service. Patch ini menambahkan utilitas informasi server, tampilan metadata akun (tanpa membocorkan UUID/password), dan audit inbound UDP.

## Instalasi

Ekstrak ZIP di VPS lalu jalankan:

```bash
apt update && apt install -y jq curl
bash install-patch.sh
```

## Perintah

```bash
dlgst-system-info all
dlgst-system-info info
dlgst-system-info bandwidth
dlgst-account-show shadowsocks test1234
dlgst-account-show vless username
dlgst-udp-audit
```

## Batasan penting

Ini adalah patch utilitas/add-on, bukan implementasi penuh seluruh protokol yang pernah dibahas. Patch ini **belum** menambahkan inbound VLESS/VMess/Trojan XHTTP, HTTP Upgrade, REALITY, mKCP, Shadowsocks native UDP, Hysteria2, MASQUE, QR generator, atau integrasi create/renew/delete. Fitur-fitur tersebut perlu dibuat sesuai versi Xray-core dan skema config yang benar, lalu diuji dengan `xray run -test -config ...` sebelum restart.

UDP pada VLESS/VMess/Trojan umumnya berarti trafik aplikasi UDP dibawa melalui sesi proxy (misalnya XUDP), bukan inbound transport UDP. mKCP adalah transport UDP terpisah. Shadowsocks WS/gRPC via plugin tidak otomatis menyediakan native UDP.

## Catatan bandwidth

`dlgst-system-info bandwidth` menampilkan counter RX/TX interface sejak interface aktif. Itu bukan rekap harian. Untuk angka TODAY/YESTERDAY seperti screenshot diperlukan pencatatan periodik (vnstat atau collector sendiri); jangan menampilkan counter interface sebagai data harian.

## Keamanan

- Tidak menampilkan UUID atau password.
- Tidak memodifikasi config maupun firewall.
- Jalankan di staging dahulu.
- Backup tetap disarankan sebelum menggabungkan ke source utama.
