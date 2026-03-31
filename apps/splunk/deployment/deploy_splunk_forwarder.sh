#!/bin/bash
# Splunk Universal Forwarder Deployment Script
# Usage: sudo ./deploy_splunk_forwarder.sh <HOST_IP> <SPLUNK_SERVER_IP>

HOST_IP=$1
SPLUNK_SERVER_IP=$2

if [ -z "$HOST_IP" ] || [ -z "$SPLUNK_SERVER_IP" ]; then
    echo "Usage: sudo ./deploy_splunk_forwarder.sh <HOST_IP> <SPLUNK_SERVER_IP>"
    echo "  <HOST_IP>: (Legacy) The IP of the Blue Team machine"
    echo "  <SPLUNK_SERVER_IP>: The IP of the Splunk Indexer (usually same as HOST_IP)"
    exit 1
fi

echo "[*] Detecting Operating System..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
else
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
fi

# Fetch payload version dynamically from host
echo "[*] Polling payload server for forwarder version..."
TARGET_VERSION=$(curl -s "http://$HOST_IP:8001/payloads/version.txt")

if [ -z "$TARGET_VERSION" ]; then
    echo "[FAIL] Could not retrieve version from http://$HOST_IP:8001/payloads/version.txt"
    exit 1
fi

echo "[*] Target Version Detected: $TARGET_VERSION"
echo "[*] Detected OS: $OS"

if [[ "$OS" == *"ubuntu"* ]] || [[ "$OS" == *"debian"* ]] || [[ "$OS" == *"kali"* ]] || [[ "$OS" == *"mint"* ]]; then
    DOWNLOAD_URL="http://$HOST_IP:8001/payloads/splunkforwarder-${TARGET_VERSION}-linux-amd64.deb"
    PAYLOAD_FILE="splunkforwarder-${TARGET_VERSION}-linux-amd64.deb"
    INSTALL_CMD="dpkg -i"
elif [[ "$OS" == *"centos"* ]] || [[ "$OS" == *"rhel"* ]] || [[ "$OS" == *"fedora"* ]] || [[ "$OS" == *"rocky"* ]] || [[ "$OS" == *"alma"* ]] || [[ "$OS" == *"amzn"* ]]; then
    DOWNLOAD_URL="http://$HOST_IP:8001/payloads/splunkforwarder-${TARGET_VERSION}-x86_64.rpm"
    PAYLOAD_FILE="splunkforwarder-${TARGET_VERSION}-x86_64.rpm"
    INSTALL_CMD="rpm -Uvh"
else
    echo "[FAIL] Unsupported OS for automated deployment: $OS"
    exit 1
fi

echo "[*] Downloading Forwarder payload from local server at $DOWNLOAD_URL..."
wget -O "$PAYLOAD_FILE" "$DOWNLOAD_URL"

if [ ! -s "$PAYLOAD_FILE" ]; then
    echo "[FAIL] Download failed. Check network connectivity or URL."
    exit 1
fi

echo "[*] Installing Forwarder..."
$INSTALL_CMD "$PAYLOAD_FILE"

echo "[*] Configuring Forwarder..."
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunkforwarder/bin/splunk set deploy-poll "$SPLUNK_SERVER_IP:8089" -auth admin:changeme
/opt/splunkforwarder/bin/splunk add forward-server "$SPLUNK_SERVER_IP:9997" -auth admin:changeme
/opt/splunkforwarder/bin/splunk add monitor /var/log/syslog

echo "[*] Restarting Forwarder..."
/opt/splunkforwarder/bin/splunk restart

echo "[+] Forwarder Deployed!"
