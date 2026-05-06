#!/bin/bash
set -e

echo "🚀 شروع نصب حرفه‌ای Reality + Subscription"

SERVER_IP=$(curl -s ifconfig.me)

# ===== تنظیمات =====
PANEL_USER="admin"
PANEL_PASS="StrongPass123!"
SNI="www.cloudflare.com"
USER_COUNT=3

# ===== پیش‌نیاز =====
apt update && apt upgrade -y
apt install -y curl jq ufw qrencode

# ===== Docker =====
apt install -y ca-certificates gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# ===== فایروال =====
ufw allow 22
ufw allow 443
ufw allow 8000
ufw --force enable

# ===== نصب Marzban =====
bash <(curl -Ls https://github.com/Gozargah/Marzban-installer/raw/master/install.sh)

sleep 15

# ===== گرفتن توکن =====
TOKEN=$(curl -s -X POST "http://localhost:8000/api/admin/token" \
-d "username=$PANEL_USER&password=$PANEL_PASS" | jq -r .access_token)

# ===== ساخت Reality =====
KEYS=$(docker exec marzban-xray xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep PrivateKey | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep PublicKey | awk '{print $2}')

SHORT_ID=$(openssl rand -hex 4)

# ===== ساخت Inbound =====
curl -s -X POST "http://localhost:8000/api/inbounds" \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d "{
  \"remark\": \"reality-auto\",
  \"protocol\": \"vless\",
  \"port\": 443,
  \"settings\": {\"clients\": []},
  \"streamSettings\": {
    \"network\": \"tcp\",
    \"security\": \"reality\",
    \"realitySettings\": {
      \"dest\": \"$SNI:443\",
      \"serverNames\": [\"$SNI\"],
      \"privateKey\": \"$PRIVATE_KEY\",
      \"shortIds\": [\"$SHORT_ID\"]
    }
  }
}"

echo "📡 Reality ساخته شد"

echo ""
echo "📱 لینک‌ها و QR:"
echo "---------------------------"

# ===== ساخت یوزرها =====
for i in $(seq 1 $USER_COUNT); do

UUID=$(cat /proc/sys/kernel/random/uuid)

curl -s -X POST "http://localhost:8000/api/users" \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d "{
  \"username\": \"user$i\",
  \"proxies\": {\"vless\": {\"id\": \"$UUID\"}},
  \"inbounds\": {\"vless\": [\"reality-auto\"]}
}"

LINK="vless://$UUID@$SERVER_IP:443?security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&flow=xtls-rprx-vision&type=tcp#user$i"

echo ""
echo "👤 user$i:"
echo "$LINK"

qrencode -t ANSIUTF8 "$LINK"

done

echo ""
echo "======================="
echo "🌐 پنل: http://$SERVER_IP:8000"
echo "👤 $PANEL_USER"
echo "🔑 $PANEL_PASS"
echo "======================="
