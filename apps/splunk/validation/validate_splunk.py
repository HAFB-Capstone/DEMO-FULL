#!/usr/bin/env python3
"""
Splunk Health Validator
Checks the Splunk API to ensure service is up and credentials are valid.
"""

import sys
import os
import requests
import time
import urllib3

# Suppress insecure request warnings for self-signed certs
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Docker maps 8089->8089 (Management Port)
API_URL = "https://localhost:8089/services/server/info?output_mode=json"
API_USER = "admin"

def check_splunk():
    api_pass = os.environ.get("SPLUNK_PASSWORD")
    if not api_pass:
        print("[FAIL] SPLUNK_PASSWORD not found in environment variables.")
        print("[HINT] Did you run 'source .env' or export the variable?")
        return False

    print(f"[*] Connecting to Splunk API at {API_URL}...")

    try:
        # Retry logic for boot-up timing
        max_retries = 3
        for attempt in range(max_retries):
            try:
                response = requests.get(
                    API_URL, 
                    auth=(API_USER, api_pass), 
                    verify=False,    # We expect self-signed certs in this lab
                    timeout=5
                )
                
                if response.status_code == 200:
                    data = response.json()
                    version = data.get("entry", [{}])[0].get("content", {}).get("version", "Unknown")
                    print(f"[PASS] Connected to Splunk Enterprise (Version: {version})")
                    return True
                elif response.status_code == 401:
                    print("[FAIL] Authentication Failed. Check SPLUNK_PASSWORD.")
                    return False
                else:
                    print(f"[WARN] API returned status {response.status_code}. Retrying...")
            
            except requests.exceptions.ConnectionError:
                print(f"[WARN] Connection refused. Splunk might still be booting ({attempt+1}/{max_retries})...")
            
            time.sleep(2)

        print("[FAIL] Could not connect to Splunk API after retries.")
        return False

    except Exception as e:
        print(f"[FAIL] Unexpected Error: {e}")
        return False

if __name__ == "__main__":
    if check_splunk():
        sys.exit(0)
    else:
        sys.exit(1)
