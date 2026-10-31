# Catatan perbaikan berdasarkan konfigurasi VPS yang dikirim

Nginx aktif menggunakan `/etc/nginx/conf.d/xray.conf`, berisi satu server block port 80 dan satu server block TLS 443. Installer transport kini menargetkan server TLS 443 secara struktural, bukan menyisipkan location sebelum kurung kurawal terakhir secara membabi buta.

Fitur yang ditambahkan oleh installer: XHTTP, HTTP Upgrade, dan mKCP untuk VMESS/VLESS/TROJAN. Installer sengaja tidak memasang REALITY atau Shadowsocks UDP secara otomatis sampai integrasi key/link dan database multi-akun diselesaikan.

**Jangan anggap semua fitur di daftar rencana sudah siap dijual.** Validasi lokal tidak sama dengan pengujian koneksi dari aplikasi klien.
