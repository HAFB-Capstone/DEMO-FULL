#!/usr/bin/env python3
"""
Payload Server
Serves files from the deployment directory so targets can download them via curl/wget.
"""

import http.server
import socketserver
import os
import sys

PORT = 8001
DIRECTORY = "deployment"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

def run_server():
    # Ensure deployment directory exists
    if not os.path.exists(DIRECTORY):
        print(f"[FAIL] Directory '{DIRECTORY}' not found.")
        sys.exit(1)

    print(f"[*] Serving payloads from '{DIRECTORY}' on port {PORT}...")
    print(f"[*] Targets can download files via: http://<HOST_IP>:{PORT}/<FILENAME>")
    print("[*] Press Ctrl+C to stop.")

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Stopping server.")
            httpd.server_close()

if __name__ == "__main__":
    run_server()
