#!/usr/bin/env python3
"""
tools/recon/nmap_scan.py
Runs an nmap scan against the target and saves results to logs/.

Usage:
    python3 tools/recon/nmap_scan.py
    python3 tools/recon/nmap_scan.py --host 192.168.56.1 --port 8080
"""

import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from config_loader import load_config, REPO_ROOT

LOGS_DIR = REPO_ROOT / "logs"


def run_nmap(host: str):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = LOGS_DIR / f"nmap_{host}_{timestamp}.txt"

    print(f"[*] Starting nmap scan on {host}:")
    print(f"[*] Results will be saved to {output_file}\n")

    commands = [
        {
            "label": "Top ports scan",
            "cmd": ["nmap", "-sV", "--top-ports", "1000", "--open", host],
        },
        {
            "label": "All ports scan",
            "cmd": ["nmap", "-sV", "-p-", "--open", host],
        },
        {
            "label": "HTTP script scan on common web ports",
            "cmd": ["nmap", "-p", "80,443,8000,8001,8002,8003", "--script", "http-enum,http-headers,http-methods", host],
        },
    ]

    all_output = []
    for item in commands:
        print(f"[*] Running: {item['label']}")
        print(f"    Command: {' '.join(item['cmd'])}\n")
        try:
            result = subprocess.run(
                item["cmd"],
                capture_output=True,
                text=True,
                timeout=60,
            )
            output = result.stdout
            print(output)
            all_output.append(f"=== {item['label']} ===\n{output}\n")
        except FileNotFoundError:
            print("[!] nmap not found. Build the attacker image and run this from the container.")
            sys.exit(1)
        except subprocess.TimeoutExpired:
            print(f"[!] Scan timed out: {item['label']}")

    with open(output_file, "w") as f:
        f.write(f"Nmap scan — {host} — {timestamp}\n{'='*60}\n\n")
        f.write("\n".join(all_output))

    print(f"[+] Scan complete. Results saved to {output_file}")


def main():
    parser = argparse.ArgumentParser(description="Nmap recon against target VM")
    parser.add_argument("--host", help="Override target host from config")
    args = parser.parse_args()

    cfg = load_config()
    host = args.host or cfg.host

    run_nmap(host)


if __name__ == "__main__":
    main()
