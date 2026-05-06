#!/bin/bash

set -e

echo "🚀 Starting FULL AUTO INSTALL..."

# ===== FIX SYSTEM =====
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confold"

# ===== INSTALL BASE =====
apt install -y curl wget jq ufw ca-certificates gnupg lsb-release

# ===== DOCKER FIX =====
apt install -y docker.io
systemctl enable docker
systemctl start docker

# check docker
docker version || { echo "Docker failed"; exit 1; }

# ===== FIREWALL =====
ufw allow 22
ufw allow 443
ufw allow 8000
ufw --force enable

# ===== MARZBAN INSTALL (SAFE RAW) =====
bash <(curl -Ls https://raw.githubusercontent.com/Gozargah/Marzban-installer/master/install.sh)

echo "✅ INSTALL DONE"
echo "🌐 Panel: http://$(curl -s ifconfig.me):8000"
