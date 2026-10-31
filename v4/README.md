# DLGST XRAY PANEL V4 – Transport upgrade

Installer `install-transports.sh` menambahkan inbound XHTTP, HTTP Upgrade, dan mKCP untuk VMESS, VLESS, dan TROJAN secara aditif.

## Cara menjalankan
```bash
sudo bash v4/install-transports.sh
```

## Perlindungan
- Backup Xray dan Nginx dibuat di `/etc/dlgst/backups/`.
- Tidak menghapus inbound lama.
- Menolak benturan port.
- Routing HTTP ditambahkan hanya ke server block TLS 443 yang terdeteksi tunggal.
- Validasi Xray dan Nginx dilakukan sebelum restart; rollback dilakukan jika gagal.

## Batasan yang harus diperhatikan
- REALITY tidak diaktifkan otomatis: perlu pemilihan SNI/target, pembuatan keypair, dan penerbitan link akun yang konsisten.
- Shadowsocks UDP belum diubah karena perlu integrasi multi-user dengan database akun yang sudah ada.
- Penambahan inbound tidak otomatis membuat script akun lama mengeluarkan link untuk transport baru. Script akun harus diselaraskan sebelum fitur itu dijual.
- mKCP menggunakan UDP langsung; buka UDP 34121–34123 di firewall VPS/provider jika dipakai.
- Ini pemeriksaan statis dan bukan pengujian koneksi klien di VPS produksi.
