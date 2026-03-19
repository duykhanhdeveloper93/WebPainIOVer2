#!/bin/bash
# Lấy SSL cert lần đầu
# Chạy: bash get-ssl.sh
# Điều kiện: domain nuocngavidai.duckdns.org đã trỏ về IP VPS

set -e
DOMAIN="nuocngavidai.duckdns.org"
EMAIL="${1:-admin@paintco.vn}"
APP_DIR="/opt/paintco"

echo "=== Lấy SSL cert cho $DOMAIN ==="

cd $APP_DIR

# Bước 1: Chạy nginx HTTP trước (chỉ dùng http.conf)
echo "[1] Khởi động nginx với HTTP..."
# Tạm thời chỉ giữ http.conf, ẩn https.conf
cp nginx/conf.d/https.conf nginx/conf.d/https.conf.disabled 2>/dev/null || true
rm -f nginx/conf.d/https.conf 2>/dev/null || true

docker compose up -d nginx certbot
sleep 5

# Bước 2: Xin cert từ Let's Encrypt
echo "[2] Xin SSL certificate..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

echo "[3] Cert lấy xong! Bật HTTPS..."

# Bước 3: Khôi phục https.conf
cp nginx/conf.d/https.conf.disabled nginx/conf.d/https.conf
rm nginx/conf.d/https.conf.disabled

# Bước 4: Reload nginx với HTTPS config
docker compose exec nginx nginx -s reload

echo ""
echo "=== SSL xong! ==="
echo "    https://$DOMAIN"
echo "    Cert tự động gia hạn mỗi 12 tiếng"
