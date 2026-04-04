#!/usr/bin/env python3
"""
tools/recon/nmap_scan.py
Runs an nmap scan against the target and saves results to logs/.

Usage:
    python3 tools/recon/nmap_scan.py
    python3 tools/recon/nmap_scan.py --host 192.168.56.1 --port 8080
"""

import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from config_loader import load_config, REPO_ROOT

LOGS_DIR = REPO_ROOT / "logs"


def demo_ports() -> list[int]:
    ports = []
    for name, default in (
        ("LOG4J_AUTH_PORT", "8101"),
        ("LOG4J_INVENTORY_PORT", "8102"),
        ("LOG4J_STATUS_PORT", "8103"),
        ("LOG4J_VULN_APP_PORT", "8180"),
    ):
        raw = os.environ.get(name, default).strip()
        try:
            port = int(raw)
        except ValueError:
            continue
        if port not in ports:
            ports.append(port)
    return ports


def run_nmap(host: str):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = LOGS_DIR / f"nmap_{host}_{timestamp}.txt"
    ports = demo_ports()
    port_arg = ",".join(str(port) for port in ports)

    print(f"[*] Starting nmap scan on {host}:")
    print(f"[*] Results will be saved to {output_file}\n")

    commands = [
        {
            "label": "Focused TCP scan on demo ports",
            "cmd": ["nmap", "-Pn", "-n", "-sT", "-sV", "-p", port_arg, "--open", host],
            "timeout": 90,
        },
        {
            "label": "HTTP script scan on demo ports",
            "cmd": [
                "nmap",
                "-Pn",
                "-n",
                "-p",
                port_arg,
                "--script",
                "http-enum,http-headers,http-methods",
                host,
            ],
            "timeout": 90,
        },
        {
            "label": "Optional broad top-ports scan",
            "cmd": ["nmap", "-Pn", "-n", "-sT", "--top-ports", "200", "--open", host],
            "timeout": 180,
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
                timeout=item.get("timeout", 60),
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
