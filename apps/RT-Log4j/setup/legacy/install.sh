#!/usr/bin/env bash
# =============================================================================
# Legacy RT-template Setup Script
# Archived during the Docker migration. Use setup/configure.sh instead.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] RT-template Setup Starting...${NC}"

echo -e "${YELLOW}[*] Updating apt and installing system tools...${NC}"
sudo apt-get update -qq
sudo apt-get install -y \
    curl \
    wget \
    nmap \
    sqlmap \
    python3 \
    python3-pip \
    python3-venv \
    gobuster \
    nikto \
    jq \
    netcat-openbsd \
    net-tools \
    git \
    maven \
    default-jdk \
    2>/dev/null

echo -e "${GREEN}[+] System packages installed.${NC}"

echo -e "${YELLOW}[*] Setting up marshalsec (Log4Shell LDAP server)...${NC}"

MARSHALSEC_DIR="$HOME/marshalsec"
MARSHALSEC_JAR="$MARSHALSEC_DIR/target/marshalsec-0.0.3-SNAPSHOT-all.jar"

if [ ! -d "$MARSHALSEC_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning marshalsec...${NC}"
    git clone https://github.com/mbechler/marshalsec.git "$MARSHALSEC_DIR"
else
    echo -e "${GREEN}[+] marshalsec repo already exists.${NC}"
fi

if ! command -v mvn &> /dev/null; then
    echo -e "${RED}[!] Maven not installed correctly.${NC}"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo -e "${RED}[!] Java not installed correctly.${NC}"
    exit 1
fi

if [ ! -f "$MARSHALSEC_JAR" ]; then
    echo -e "${YELLOW}[*] Building marshalsec (this may take a minute)...${NC}"
    (cd "$MARSHALSEC_DIR" && mvn clean package -DskipTests -q)
else
    echo -e "${GREEN}[+] marshalsec already built.${NC}"
fi

if [ ! -f "$MARSHALSEC_JAR" ]; then
    echo -e "${RED}[!] marshalsec build failed - jar not found.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] marshalsec ready: ${MARSHALSEC_JAR}${NC}"

echo -e "${YELLOW}[*] Setting up JNDIExploit...${NC}"

JNDI_DIR="$HOME/tools/jndi"
JNDI_JAR="$JNDI_DIR/JNDIExploit-1.2-SNAPSHOT.jar"

mkdir -p "$JNDI_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLED_JAR="$SCRIPT_DIR/setup/tools/JNDIExploit-1.2-SNAPSHOT.jar"

if [ ! -f "$JNDI_JAR" ]; then
    if [ -f "$BUNDLED_JAR" ]; then
        cp "$BUNDLED_JAR" "$JNDI_JAR"
        echo -e "${GREEN}[+] JNDIExploit installed from repo bundle.${NC}"
    else
        echo -e "${RED}[!] JNDIExploit jar not found at $BUNDLED_JAR${NC}"
        echo -e "${RED}[!] Ensure setup/tools/JNDIExploit-1.2-SNAPSHOT.jar exists in the repo.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[+] JNDIExploit already present.${NC}"
fi

if [ ! -f "$JNDI_JAR" ]; then
    echo -e "${RED}[!] JNDIExploit install failed.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] JNDIExploit ready: ${JNDI_JAR}${NC}"

echo -e "${YELLOW}[*] Setting up Python virtual environment...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

python3 -m venv .venv
source .venv/bin/activate

pip install --quiet --upgrade pip
pip install --quiet -r "$SCRIPT_DIR/requirements.txt"

echo -e "${GREEN}[+] Python environment ready. Activate with: source .venv/bin/activate${NC}"

KALI_IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}[*] Detected Kali IP: ${KALI_IP}${NC}"

read -p "$(echo -e ${YELLOW}[?] Enter the vulnerable VM target IP: ${NC})" TARGET_IP

python3 - <<EOF
import yaml

with open('$SCRIPT_DIR/config/target.yaml', 'r') as f:
    config = yaml.safe_load(f)

config['target']['host'] = '$TARGET_IP'
config['attacker']['host'] = '$KALI_IP'

with open('$SCRIPT_DIR/config/target.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False)
EOF

echo -e "${GREEN}[+] config/target.yaml updated:${NC}"
echo -e "    Target:   ${YELLOW}$TARGET_IP${NC}"
echo -e "    Attacker: ${YELLOW}$KALI_IP${NC}"

echo -e "${YELLOW}[*] Checking target host connectivity...${NC}"

if ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}[+] Target host is reachable (ICMP).${NC}"
else
    echo -e "${YELLOW}[!] Ping failed - ICMP may be blocked. Trying TCP check...${NC}"

    if nc -z -w2 "$TARGET_IP" 22 || nc -z -w2 "$TARGET_IP" 8001 || nc -z -w2 "$TARGET_IP" 80; then
        echo -e "${GREEN}[+] Target host is reachable (TCP).${NC}"
    else
        echo -e "${RED}[!] Unable to reach target host.${NC}"
        echo -e "${RED}[!] Check VM networking and IP configuration.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}[*] Setup complete!${NC}"
echo -e "    Activate venv:     ${YELLOW}source .venv/bin/activate${NC}"
echo -e "    Run recon:         ${YELLOW}python3 tools/recon/nmap_scan.py${NC}"
echo -e "    Add exploits to:   ${YELLOW}tools/exploit/${NC}"
echo -e "    Run Log4Shell RCE: ${YELLOW}java -jar ~/tools/jndi/JNDIExploit-1.2-SNAPSHOT.jar -i \$KALI_IP -p 8888${NC}"
echo ""
