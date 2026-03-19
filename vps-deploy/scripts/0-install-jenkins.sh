#!/bin/bash
# ================================================================
#  Cai Jenkins tren VPS Ubuntu 22.04
#  VPS: 103.77.243.178
#  Chay: sudo bash 0-install-jenkins.sh
# ================================================================
set -e
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${G}[OK]${NC} $1"; }
step() { echo -e "${B}[>>]${NC} $1"; }
warn() { echo -e "${Y}[!!]${NC} $1"; }

echo ""
echo "================================================"
echo "  Cai Jenkins + Java + NodeJS + Docker"
echo "  VPS: 103.77.243.178"
echo "================================================"
echo ""

[ "$EUID" -ne 0 ] && { echo "Chay voi sudo!"; exit 1; }

# ── 1. Java 17 ──────────────────────────────────────────────────
step "1. Cai Java 17..."
apt-get update -qq
apt-get install -y -qq fontconfig openjdk-17-jre-headless
java -version 2>&1 | head -1
ok "Java 17 OK"

# ── 2. Jenkins (cach chuan tu jenkins.io) ───────────────────────
step "2. Cai Jenkins..."
wget -qO /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update -qq
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins
sleep 5
systemctl is-active jenkins && ok "Jenkins running" || { echo "Jenkins loi!"; journalctl -u jenkins -n 20; exit 1; }

# ── 3. NodeJS 20 (de jenkins chay npm) ─────────────────────────
step "3. Cai NodeJS 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs
node -v && npm -v
ok "NodeJS $(node -v)"

# ── 4. Docker (neu chua co) ─────────────────────────────────────
step "4. Cai Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker && systemctl start docker
fi
# Them jenkins vao nhom docker (quan trong!)
usermod -aG docker jenkins
ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"

# ── 5. Git ──────────────────────────────────────────────────────
step "5. Kiem tra Git..."
apt-get install -y -qq git
git --version
ok "Git OK"

# ── 6. Tao thu muc app cho Jenkins deploy vao ───────────────────
step "6. Tao /opt/paintco..."
mkdir -p /opt/paintco
chown jenkins:jenkins /opt/paintco
ok "/opt/paintco san sang, Jenkins co quyen ghi"

# ── 7. Firewall ─────────────────────────────────────────────────
step "7. Mo port 8080 tam thoi (setup xong se dong lai)..."
ufw allow 8080/tcp 2>/dev/null || true
ok "Port 8080 mo"

# ── 8. In mat khau ──────────────────────────────────────────────
echo ""
echo "================================================"
echo "  Jenkins da cai xong!"
echo ""
echo "  Truy cap: http://103.77.243.178:8080"
echo ""
echo "  Mat khau admin:"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "  Sau khi setup Jenkins xong, chay:"
echo "  bash /opt/paintco/vps-deploy/scripts/1-setup-vps.sh"
echo "================================================"
