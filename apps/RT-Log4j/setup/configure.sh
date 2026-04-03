#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/target.yaml"

detect_attacker_ip() {
    local detected_ip=""
    local candidate_ips=""

    if command -v hostname >/dev/null 2>&1; then
        candidate_ips="$(hostname -I 2>/dev/null | tr ' ' '\n' | sed '/^$/d')"
    fi

    if [ -z "$candidate_ips" ] && command -v ifconfig >/dev/null 2>&1; then
        candidate_ips="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2}')"
    fi

    if [ -n "$candidate_ips" ]; then
        detected_ip="$(printf '%s\n' "$candidate_ips" | awk '
            /^192\.168\.56\./ { print; exit }
            /^192\.168\./ && !found { preferred=$0; found=1 }
            /^172\.(1[6-9]|2[0-9]|3[0-1])\./ && !found172 { preferred172=$0; found172=1 }
            /^10\./ && !found10 { preferred10=$0; found10=1 }
            END {
                if (preferred != "") print preferred;
                else if (preferred172 != "") print preferred172;
                else if (preferred10 != "") print preferred10;
            }
        ')"
    fi

    if [ -z "$detected_ip" ] && command -v ip >/dev/null 2>&1; then
        detected_ip="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i = 1; i <= NF; i++) if ($i == "src") {print $(i+1); exit}}')"
    fi

    printf '%s' "$detected_ip"
}

check_tcp_port() {
    local host="$1"
    local port="$2"

    timeout 2 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" >/dev/null 2>&1
}

write_config() {
    local target_ip="$1"
    local attacker_ip="$2"

    cat > "$CONFIG_FILE" <<EOF
# RT-template Target Configuration
# Updated by setup/configure.sh for the active lab.

target:
  host: "$target_ip"

# Attacker listener
attacker:
  host: "$attacker_ip"
  port: 9999
EOF
}

echo -e "${GREEN}[*] RT-Log4j environment configuration${NC}"

ATTACKER_IP="${ATTACKER_HOST:-$(detect_attacker_ip)}"
if [ -z "$ATTACKER_IP" ]; then
    echo -e "${RED}[!] Unable to auto-detect the attacker IP.${NC}"
    echo -e "${RED}[!] Set ATTACKER_HOST manually and rerun setup/configure.sh.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Detected attacker IP: ${ATTACKER_IP}${NC}"

DEFAULT_TARGET="${TARGET_HOST:-}"
if [ -n "$DEFAULT_TARGET" ]; then
    prompt="[*] Enter the target VM IP [${DEFAULT_TARGET}]: "
else
    prompt="[*] Enter the target VM IP: "
fi

read -r -p "$prompt" TARGET_IP
TARGET_IP="${TARGET_IP:-$DEFAULT_TARGET}"

if [ -z "$TARGET_IP" ]; then
    echo -e "${RED}[!] A target VM IP is required.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Writing ${CONFIG_FILE}...${NC}"
write_config "$TARGET_IP" "$ATTACKER_IP"

echo -e "${YELLOW}[*] Verifying connectivity to ${TARGET_IP}...${NC}"
if ping -c 1 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Target responded to ICMP.${NC}"
else
    echo -e "${YELLOW}[!] Ping failed. Trying TCP fallback on common lab ports...${NC}"
    if check_tcp_port "$TARGET_IP" 8001 || check_tcp_port "$TARGET_IP" 8002 || check_tcp_port "$TARGET_IP" 8003 || check_tcp_port "$TARGET_IP" 22 || check_tcp_port "$TARGET_IP" 80; then
        echo -e "${GREEN}[+] Target responded to a TCP connectivity check.${NC}"
    else
        echo -e "${RED}[!] Unable to confirm reachability with ICMP or TCP fallback.${NC}"
        echo -e "${RED}[!] Check VM networking before you launch the attacker container.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}[*] Configuration summary${NC}"
echo -e "    Target VM:   ${YELLOW}${TARGET_IP}${NC}"
echo -e "    Attacker IP: ${YELLOW}${ATTACKER_IP}${NC}"
echo -e "    Config file: ${YELLOW}${CONFIG_FILE}${NC}"
echo ""
echo -e "${GREEN}[*] Next steps${NC}"
echo -e "    1. ${YELLOW}make build${NC}"
echo -e "    2. ${YELLOW}make up${NC}"
echo -e "    3. ${YELLOW}make shell${NC}"
echo -e "    4. Inside the container, run ${YELLOW}python3 tools/recon/nmap_scan.py${NC}"
