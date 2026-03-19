#!/bin/bash
# Deploy thu cong lan dau (truoc khi Jenkins hoat dong)
# Sau nay Jenkins tu dong deploy khi push code
set -e
APP_DIR="/opt/paintco"
COMPOSE="docker compose -f ${APP_DIR}/docker-compose.vps.yml"
ENV_FILE="${APP_DIR}/.env.production"

echo "=== Deploy PaintCo (Thu cong) ==="
echo "Sau khi Jenkins setup xong, lenh nay khong can chay nua"
echo ""

# Clone code neu chua co
if [ ! -d "${APP_DIR}/.git" ]; then
  echo "Clone code tu GitHub..."
  git clone -b develop \
    https://github.com/duykhanhdeveloper93/WebPainIO.git \
    ${APP_DIR}
  echo "Clone OK"
fi

# Kiem tra .env
if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "Chua co .env.production!"
  echo "Chay: cp ${APP_DIR}/.env.production.example ${APP_DIR}/.env.production"
  echo "Roi: nano ${APP_DIR}/.env.production"
  echo "Roi chay lai script nay"
  exit 1
fi

# Build va chay
echo "Building..."
$COMPOSE --env-file $ENV_FILE build

echo "Starting..."
$COMPOSE --env-file $ENV_FILE up -d

echo "Waiting MySQL..."
sleep 20

# Seed
if [ ! -f "${APP_DIR}/.seeded" ]; then
  echo "Seeding..."
  $COMPOSE exec -T backend node dist/database/seed.js && touch "${APP_DIR}/.seeded"
fi

echo ""
echo "=== Deploy xong! ==="
$COMPOSE ps
echo ""
echo "Truy cap: http://103.77.243.178"
echo "Tiep theo: bash 3-ssl.sh DOMAIN.duckdns.org"
