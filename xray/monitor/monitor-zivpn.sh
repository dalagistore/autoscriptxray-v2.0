#!/usr/bin/env bash
set -u
if systemctl is-active --quiet zivpn 2>/dev/null; then
    echo 'ZIVPN SERVICE: RUNNING'
else
    echo 'ZIVPN SERVICE: STOPPED'
fi
echo 'CLIENT STATUS: UNKNOWN'
echo 'Keterangan: sumber log/API sesi pelanggan ZIVPN belum tersedia; service RUNNING bukan berarti ada pelanggan online.'
