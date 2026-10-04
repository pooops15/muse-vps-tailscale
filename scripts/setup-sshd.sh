#!/bin/bash
# setup-sshd.sh — pasang & nyalakan sshd khusus project ini di sisi VM Muse.
#
# Yang dikerjakan:
#   1. Install openssh-server kalau belum ada (Linux/Debian-Ubuntu).
#   2. Bikin folder run/, host key, dan file authorized_keys (kosong dulu)
#      di folder project — semua persisten di $HOME, bukan di /etc.
#   3. Nulis sshd_config dari sshd_config.example.
#   4. Nyalakan sshd: dengar HANYA di 127.0.0.1, login password MATI,
#      yang boleh masuk cuma kunci di authorized_keys.
#
# Parameter lewat environment (semua opsional):
#   PROJECT_DIR    folder project (default: folder tempat skrip ini berada/..)
#   SSH_LOCAL_PORT port lokal sshd (default: 2222)
#
# Setelah skrip ini jalan, tempel kunci PUBLIK milikmu (dari laptop) ke
# file authorized_keys di folder project — satu baris, satu kunci.
set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
SSH_LOCAL_PORT="${SSH_LOCAL_PORT:-2222}"
export PROJECT_DIR SSH_LOCAL_PORT

cd "$PROJECT_DIR"
mkdir -p run

# 1. Pastikan sshd tersedia
if [ ! -x /usr/sbin/sshd ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq openssh-server
fi

# Folder privilege separation yang dituntut sshd (hilang tiap mesin restart,
# jadi selalu dibuat ulang di sini).
mkdir -p /run/sshd; chown root:root /run/sshd 2>/dev/null || true; chmod 755 /run/sshd

# 2. Host key + authorized_keys (dibuat sekali, sesudah itu jangan ditimpa)
[ -f host_key ] || ssh-keygen -q -t ed25519 -f host_key -N ''
[ -f authorized_keys ] || touch authorized_keys
chmod 600 host_key authorized_keys

# 3. sshd_config dari contoh
sed -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    -e "s|__SSH_LOCAL_PORT__|$SSH_LOCAL_PORT|g" \
    scripts/sshd_config.example > sshd_config

# 4. Nyalakan (atau laporkan kalau sudah jalan)
/usr/sbin/sshd -t -f "$PROJECT_DIR/sshd_config"
if [ -f run/sshd.pid ] && kill -0 "$(cat run/sshd.pid)" 2>/dev/null; then
  echo "sshd sudah jalan (pid $(cat run/sshd.pid), port $SSH_LOCAL_PORT)"
else
  /usr/sbin/sshd -f "$PROJECT_DIR/sshd_config" -E "$PROJECT_DIR/sshd.log"
  echo "sshd dinyalakan di 127.0.0.1:$SSH_LOCAL_PORT (key-only, tanpa password)"
fi
echo "Langkah berikutnya: tempel kunci publik laptopmu ke $PROJECT_DIR/authorized_keys"
