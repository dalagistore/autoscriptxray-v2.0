#!/usr/bin/env bash
# DLGST XRAY PANEL V4 - single entry-point installer

# Always require root before changing the system.
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "[ERROR] Jalankan sebagai root: sudo bash setup.sh"
    exit 1
fi

# This project targets Debian 12.
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
else
    echo "[ERROR] Tidak dapat membaca /etc/os-release."
    exit 1
fi
if [[ "${ID:-}" != "debian" || "${VERSION_ID:-}" != "12" ]]; then
    echo "[ERROR] DLGST XRAY PANEL V4 menargetkan Debian 12. Sistem terdeteksi: ${PRETTY_NAME:-unknown}"
    exit 1
fi

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/root/autoscriptxray"

# If launched from a cloned/downloaded directory, stage the source in the
# canonical location. Never overwrite an existing installation automatically.
if [[ "$SOURCE_DIR" != "$INSTALL_DIR" ]]; then
    if [[ -e "$INSTALL_DIR" ]]; then
        echo "[ERROR] $INSTALL_DIR sudah ada. Demi keamanan, setup tidak akan menimpa instalasi/data yang ada."
        echo "Backup dan audit instalasi lama terlebih dahulu, atau jalankan setup a partir de $INSTALL_DIR setelah memastikan source-nya benar."
        exit 1
    fi
    echo "[INFO] Menyiapkan source di $INSTALL_DIR ..."
    install -d -m 0755 "$INSTALL_DIR"
    cp -a "$SOURCE_DIR"/. "$INSTALL_DIR"/
    chmod +x "$INSTALL_DIR/setup.sh" "$INSTALL_DIR"/install/*.sh 2>/dev/null || true
    exec bash "$INSTALL_DIR/setup.sh"
fi

# ==========================================
# Setup Script XRAY_AIO
# XRAY + WireGuard + UDP ZIVPN
# ==========================================

echo "" > /root/log-install.txt

cd "$(dirname "$0")"

clear

# ==========================================
# COLOR
# ==========================================

red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
cyan='\e[1;36m'
NC='\e[0m'

# ==========================================
# FUNCTION
# ==========================================

function info() {
    echo -e "${green}[INFO]${NC} $1"
}

function warn() {
    echo -e "${yellow}[WARNING]${NC} $1"
}

function error() {
    echo -e "${red}[ERROR]${NC} $1"
}

# ==========================================
# TIMER
# ==========================================

start_time=$(date +%s)

# ==========================================
# ==========================================
# CHECK VIRTUALIZATION
# ==========================================

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    error "OpenVZ tidak didukung. Gunakan KVM/VMWare."
    exit 1
fi

# ==========================================
# FIX /etc/hosts
# ==========================================

localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)

domainline=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')

if [[ "$hostname" != "$domainline" ]]; then
    echo "$localip $hostname" >> /etc/hosts
fi

# ==========================================
# CREATE REQUIRED FOLDER
# ==========================================

mkdir -p /etc/xray
mkdir -p /etc/v2ray
mkdir -p /var/lib

for file in domain scdomain; do
    touch /etc/xray/$file
    touch /etc/v2ray/$file
    touch /root/$file
done

touch /var/lib/ipvps.conf

# ==========================================
# SET TIMEZONE
# ==========================================

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ==========================================
# UPDATE & INSTALL PACKAGE
# ==========================================

info "Installing dependencies..."

apt update -y

apt install -y \
curl \
wget \
git \
screen \
unzip \
bzip2 \
gzip \
coreutils \
python3 \
python3-pip \
iptables \
iptables-persistent \
netfilter-persistent \
vnstat \
openssl \
jq \
ufw >/dev/null 2>&1

# ==========================================
# INSTALL LINUX HEADER
# ==========================================

kernelver=$(uname -r)
headerpkg="linux-headers-$kernelver"

if ! dpkg -s $headerpkg >/dev/null 2>&1; then
    info "Installing $headerpkg..."
    apt install -y $headerpkg
fi

# ==========================================
# DOMAIN SETUP
# ==========================================

clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${cyan}         DOMAIN SETUP${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -rp "Masukkan domain kamu : " domain

if [[ -z "$domain" ]]; then
    error "Domain tidak boleh kosong!"
    exit 1
fi

echo "$domain" > /root/domain

for dfile in domain scdomain; do
    echo "$domain" > /etc/xray/$dfile
    echo "$domain" > /etc/v2ray/$dfile
    echo "$domain" > /root/$dfile
done

echo "IP=$domain" > /var/lib/ipvps.conf

echo ""
info "Domain berhasil diset: $domain"

sleep 2

# ==========================================
# RUN INSTALLER
# ==========================================

info "Installing NGINX Reverse Proxy..."
bash install/nginx.sh

info "Installing XRAY Core..."
bash install/xray.sh

info "Installing DLGST V4 transport modules (XHTTP/HTTPUpgrade/REALITY/mKCP/SS UDP/Hysteria2)..."
bash v4/install-all.sh

info "Installing SSH Websocket..."
bash install/ssh.sh

info "Installing WireGuard..."
bash install/wg.sh

info "Installing UDP ZIVPN..."
bash install/zivpn.sh

# ==========================================
# INSTALL DLGST ONLINE MONITOR
# ==========================================

info "Installing DLGST Online Monitor..."
if [[ -f install/install-monitor.sh ]]; then
    bash install/install-monitor.sh
else
    warn "Installer Online Monitor tidak ditemukan; lanjut instalasi utama."
fi

# ==========================================
# COPY MENU COMMAND
# ==========================================

info "Menyalin command menu..."

cp -f ssh/m-ssh /usr/bin/

cp -f xray/m-vmess /usr/bin/
cp -f xray/m-vless /usr/bin/
cp -f xray/m-trojan /usr/bin/
cp -f xray/m-ssws /usr/bin/

cp -f wg/m-wg /usr/bin/

cp -f udp/m-zivpn /usr/bin/

cp -f tools/tools-menu /usr/bin/

cp -f tools/backup.sh /usr/bin/
cp -f tools/speedtest.sh /usr/bin/
cp -f tools/domain.sh /usr/bin/
cp -f tools/running.sh /usr/bin/

cp -f menu.sh /usr/bin/menu

# ==========================================
# SET PERMISSION
# ==========================================

chmod +x /usr/bin/menu

chmod +x /usr/bin/m-ssh
chmod +x /usr/bin/m-vmess
chmod +x /usr/bin/m-vless
chmod +x /usr/bin/m-trojan
chmod +x /usr/bin/m-ssws
chmod +x /usr/bin/m-wg
chmod +x /usr/bin/m-zivpn

chmod +x /usr/bin/tools-menu
chmod +x /usr/bin/backup.sh
chmod +x /usr/bin/speedtest.sh
chmod +x /usr/bin/domain.sh
chmod +x /usr/bin/running.sh

chmod +x ssh/*.sh
chmod +x xray/*.sh
chmod +x wg/*.sh
chmod +x udp/*.sh
chmod +x tools/*.sh

# ==========================================
# COPY RUNTIME SCRIPT
# ==========================================

info "Menyalin semua submenu ke /etc/autoscriptvpn/..."

mkdir -p /etc/autoscriptvpn/{ssh,xray,wg,udp,tools}

cp -r ssh/* /etc/autoscriptvpn/ssh/
cp -r xray/* /etc/autoscriptvpn/xray/
cp -r wg/* /etc/autoscriptvpn/wg/
cp -r udp/* /etc/autoscriptvpn/udp/
cp -r tools/* /etc/autoscriptvpn/tools/

chmod +x /etc/autoscriptvpn/*/*.sh

# ==========================================
# DLGST V4 BUILT-IN UTILITIES (NO MANUAL PATCH)
# ==========================================
info "Installing integrated DLGST V4 utilities..."
if [[ -f addons/v4-feature-patch/install-patch.sh ]]; then
    bash addons/v4-feature-patch/install-patch.sh
else
    warn "V4 utilities source missing; continuing legacy installation."
fi

# ==========================================
# AUTO MENU LOGIN
# ==========================================

cat > /root/.profile <<-EOF
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

clear
menu
EOF

chmod 644 /root/.profile

# ==========================================
# CLEAN FILE
# ==========================================

rm -f cf
rm -f ins-xray.sh

# ==========================================
# FINISH
# ==========================================

end_time=$(date +%s)

elapsed=$((end_time - start_time))

clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${green}      INSTALLATION DONE${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e " SSH         : INSTALLED"
echo -e " XRAY        : INSTALLED"
echo -e " WireGuard   : INSTALLED"
echo -e " UDP ZIVPN   : INSTALLED"

echo ""
echo -e " Installation Time : $((elapsed / 60)) menit $((elapsed % 60)) detik"

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${yellow}Restart VPS secara manual jika diperlukan: reboot${NC}"
echo -e "${green}Instalasi selesai. Tidak melakukan reboot otomatis.${NC}"
