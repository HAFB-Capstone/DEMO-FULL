#!/bin/bash
# Host Setup Script
# Prepares the Blue Team Host environment.

# Check/Create .env
if [ ! -f .env ]; then
    echo "[*] Creating .env from template..."
    cp .env.example .env
    echo "[!] .env created. Please edit it to set your secure password."
fi

# Load .env
export $(grep -v '^#' .env | xargs)

# Check for Payloads
PAYLOAD_DIR="deployment/payloads"
mkdir -p "$PAYLOAD_DIR"
DEB_FILE="splunkforwarder-${SPLUNK_FORWARDER_VERSION}-linux-amd64.deb"
RPM_FILE="splunkforwarder-${SPLUNK_FORWARDER_VERSION}-x86_64.rpm"
DEB_PATH="$PAYLOAD_DIR/$DEB_FILE"
RPM_PATH="$PAYLOAD_DIR/$RPM_FILE"

# URLs for dynamic version
DEB_URL="https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_FORWARDER_VERSION}/linux/splunkforwarder-${SPLUNK_FORWARDER_VERSION}-${SPLUNK_FORWARDER_HASH}-linux-2.6-amd64.deb"
RPM_URL="https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_FORWARDER_VERSION}/linux/splunkforwarder-${SPLUNK_FORWARDER_VERSION}-${SPLUNK_FORWARDER_HASH}.x86_64.rpm"

if [ ! -f "$DEB_PATH" ]; then
    echo "[!] Debian Universal Forwarder ($DEB_FILE) not found."
    echo "[*] Downloading directly from Splunk..."
    wget -O "$DEB_PATH" "$DEB_URL" || echo "[WARN] Failed to download $DEB_FILE"
fi

if [ ! -f "$RPM_PATH" ]; then
    echo "[!] RPM Universal Forwarder ($RPM_FILE) not found."
    echo "[*] Downloading directly from Splunk..."
    wget -O "$RPM_PATH" "$RPM_URL" || echo "[WARN] Failed to download $RPM_FILE"
fi

if [ ! -f "$DEB_PATH" ] && [ ! -f "$RPM_PATH" ]; then
    echo "[FAIL] Could not download payloads automatically."
    echo "[*] Opening browser to Splunk Download page..."
    # Linux (Desktops)
    xdg-open "https://www.splunk.com/en_us/download/universal-forwarder.html" 2>/dev/null || echo "[WARN] Could not open browser. Please visit Splunk.com manually."
    
    echo ""
    echo "[ACTION REQUIRED] Download the ${SPLUNK_FORWARDER_VERSION} .deb and .rpm files and save them to: $PWD/$PAYLOAD_DIR/"
    echo "Press Enter when you have placed the files."
    read
    
    if [ ! -f "$DEB_PATH" ] && [ ! -f "$RPM_PATH" ]; then
        echo "[FAIL] Files still not found. Exiting."
        exit 1
    fi
fi

# Write version.txt so target machines can sync what version to pull
echo "${SPLUNK_FORWARDER_VERSION}" > "$PAYLOAD_DIR/version.txt"

# Start Payload Server (skip when integrated with root compose: splunk-payloads service)
echo "[*] Configuration complete."
if [ "${SKIP_SERVE:-0}" = "1" ]; then
    echo "[*] SKIP_SERVE=1 — payload server is run separately (e.g. docker compose splunk-payloads)."
    exit 0
fi
echo "[*] Starting Payload Server..."
python3 deployment/serve.py
