# Jenkins + HTTPS Setup
# Domain: nuocngavidai.duckdns.org | VPS: 103.77.243.178

---

## BƯỚC 1 — Push code lên GitHub (từ máy tính)

```bash
cd paintco
git init
git add .
git commit -m "init"
git branch -M develop
git remote add origin https://github.com/duykhanhdeveloper93/WebPainIOVer2.git
git push -u origin develop
```

---

## BƯỚC 2 — Cài Jenkins trên VPS

```bash
ssh root@103.77.243.178

# Java 17
apt update && apt install -y fontconfig openjdk-17-jre

# Jenkins
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update && apt install -y jenkins
systemctl enable jenkins && systemctl start jenkins

# Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker jenkins
systemctl restart jenkins

# NodeJS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Mật khẩu Jenkins
cat /var/lib/jenkins/secrets/initialAdminPassword
```

Mở: **http://103.77.243.178:8080** → setup như bình thường

---

## BƯỚC 3 — Tạo Pipeline Job trong Jenkins

**New Item → paintco → Pipeline → OK**

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: Pipeline script from SCM
- SCM: Git
- URL: `https://github.com/duykhanhdeveloper93/WebPainIOVer2.git`
- Branch: `*/develop`
- Script Path: `Jenkinsfile`

→ **Save**

---

## BƯỚC 4 — Tạo .env.production trên VPS (1 lần)

```bash
mkdir -p /opt/paintco
nano /opt/paintco/.env.production
```

Paste vào:
```env
DB_PASSWORD=MatKhauManhCuaMay@2024
MYSQL_ROOT_PASSWORD=RootPassManhCuaMay@2024
JWT_SECRET=ChuoiNgauNhien64KyTuBatKyVDaBcDeFgHiJkLmN123456789
```

---

## BƯỚC 5 — Build lần đầu (thủ công)

Jenkins → job **paintco** → **Build Now**

Jenkins sẽ:
1. Clone code từ GitHub về `/opt/paintco/`
2. Build Docker: backend + frontend + nginx + certbot
3. Chạy `docker compose up`
4. App live tại `http://nuocngavidai.duckdns.org`

---

## BƯỚC 6 — Lấy SSL cert (1 lần duy nhất)

```bash
# Trên VPS sau khi Build lần đầu xong
bash /opt/paintco/vps-deploy/scripts/get-ssl.sh
```

Xong → `https://nuocngavidai.duckdns.org` ✅

**SSL tự động gia hạn** — container certbot chạy ngầm, kiểm tra mỗi 12 tiếng.

---

## BƯỚC 7 — GitHub Webhook

GitHub repo → **Settings → Webhooks → Add webhook**
```
Payload URL:  http://103.77.243.178:8080/github-webhook/
Content type: application/json
Events:       Just the push event ✅
```

---

## Từ đây chỉ cần:

```bash
git push origin develop
# → Jenkins tự build → deploy → https://nuocngavidai.duckdns.org
```

---

## Lệnh debug

```bash
# Xem tất cả containers
docker compose -f /opt/paintco/docker-compose.yml ps

# Xem logs
docker compose -f /opt/paintco/docker-compose.yml logs -f backend
docker compose -f /opt/paintco/docker-compose.yml logs -f nginx

# Test SSL cert
docker compose -f /opt/paintco/docker-compose.yml run --rm certbot certificates
```
