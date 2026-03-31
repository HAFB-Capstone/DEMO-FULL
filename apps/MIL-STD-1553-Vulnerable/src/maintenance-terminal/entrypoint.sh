#!/bin/bash

PORTAL_URL="http://logistics-portal:8080/uploads/daily_maintenance.sh"
LOCAL_SCRIPT="/tmp/daily_maintenance.sh"

echo "[*] Maintenance Terminal Started. Waiting for logistics orders..."

while true; do
    echo "[*] Checking logistics portal for maintenance orders..."
    
    # Try to download the maintenance script
    # -s: Silent mode
    # -f: Fail silently (don't output if 404)
    if curl -s -f "$PORTAL_URL" -o "$LOCAL_SCRIPT"; then
        echo "[!] New maintenance order received via NIPRNet!"

        # Execute daily maintenance script
        chmod +x "$LOCAL_SCRIPT"

        echo "[*] Executing maintenance routine..."
        # Execute in a subshell so it doesn't kill our main loop if it exits
        (bash "$LOCAL_SCRIPT")

        # Cleanup
        rm "$LOCAL_SCRIPT"
    else
        echo "[-] No orders found (404). Standing by..."
    fi

    # Crew Chief takes a coffee break
    sleep 10
done
