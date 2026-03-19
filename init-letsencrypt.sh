#!/bin/sh

DOMAIN="nuocngavidai.duckdns.org"
EMAIL="duykhanhdeveloper93@gmail.com"  # 👉 sửa email của mày

echo "===== INIT SSL FOR $DOMAIN ====="

# check đã có cert chưa
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo "❌ Chưa có cert → tạo mới..."

  certbot certonly \
    --webroot \
    -w /var/www/certbot \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email

  echo "✅ Tạo cert thành công"
else
  echo "✅ Cert đã tồn tại → bỏ qua"
fi