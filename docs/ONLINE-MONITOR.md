# DLGST ONLINE MONITOR

Modul monitoring modular untuk DLGST XRAY PANEL. Dirancang untuk Debian 12 dan Bash/Python 3.

## Struktur

```text
xray/
├── online-monitor-menu.sh
├── client-monitor.sh
├── online-monitor.sh
├── activity-count.sh
└── monitor/
    ├── monitor-common.sh
    ├── monitor-xray.sh
    ├── monitor-ssh.sh
    ├── monitor-wireguard.sh
    ├── monitor-zivpn.sh
    └── monitor-udp-custom.sh
install/
└── install-monitor.sh
```

## Instalasi / pembaruan

Ekstrak repository/patch pada server, lalu dari root repository jalankan:

```bash
chmod +x install/install-monitor.sh
bash install/install-monitor.sh
```

Installer memasang file ke `/root/autoscriptxray/xray` (dapat diubah dengan `DLGST_PANEL_BASE`). File lama yang akan ditimpa dicadangkan di `backup/online-monitor-TIMESTAMP`. Installer tidak mengubah `/etc/xray/config.json`, konfigurasi Nginx, database akun, atau me-restart service.

## Menjalankan

```bash
bash /root/autoscriptxray/xray/online-monitor-menu.sh
# atau monitor gabungan langsung
bash /root/autoscriptxray/xray/online-monitor.sh
```

## Konfigurasi opsional

```bash
DLGST_XRAY_CONFIG=/etc/xray/config.json
DLGST_XRAY_ACCESS_LOG=/var/log/xray/access.log
DLGST_MONITOR_WINDOW=600
DLGST_PANEL_BASE=/root/autoscriptxray
```

Default jendela aktivitas Xray adalah 600 detik (10 menit).

## Arti status dan batasan data

- `ACTIVITY`: Xray access log memiliki event `accepted` dalam jendela waktu. Ini **bukan** bukti sesi masih tersambung.
- `ONLINE` pada UDP-Custom: event `Client connected` belum diikuti `Client disconnected` untuk endpoint sumber yang sama pada journal yang dibaca. Ketepatan bergantung pada log yang masih tersedia dan format log aplikasi.
- `ADMIN`: sesi root pada `who`; tidak dihitung sebagai pelanggan.
- `RECENT-HANDSHAKE`: peer WireGuard memiliki handshake dalam 180 detik. Ini bukan jaminan sesi aktif terus-menerus.
- `UNKNOWN`: sumber telemetry sesi pelanggan belum tersedia (saat ini ZIVPN).
- `RUNNING` adalah status service, bukan jumlah pengguna online.

Xray yang berada di belakang Nginx dapat mencatat sumber `127.0.0.1`. Modul tidak menampilkan alamat itu sebagai IP pelanggan. Tidak ada korelasi otomatis antara username Xray dan IP/User-Agent Nginx karena korelasi timestamp saja dapat salah ketika beberapa pengguna terhubung bersamaan.

SSH menampilkan sesi interaktif dari `who` dan endpoint TCP dari `ss`. Endpoint TCP tidak dipasangkan secara spekulatif ke username.

## Pengujian

Validasi sintaks shell:

```bash
find xray install -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

Pemeriksaan konfigurasi Xray hanya membaca file JSON; monitor tidak menulis konfigurasi.

## Catatan pengembangan

ZIVPN belum memiliki parser sesi karena log yang tersedia di server belum menunjukkan event login/logout pelanggan yang dapat diandalkan. Jangan mengubah statusnya menjadi ONLINE hanya berdasarkan service aktif atau socket UDP.


## Integrasi instalasi pertama
`setup.sh` menjalankan `install/install-monitor.sh` setelah instalasi komponen VPN. Menu utama menyediakan pilihan `[14] ONLINE MONITOR`. Installer membuat backup bila menimpa file monitor lama, memeriksa sintaks Bash, dan tidak mengubah akun maupun konfigurasi Xray/Nginx.
