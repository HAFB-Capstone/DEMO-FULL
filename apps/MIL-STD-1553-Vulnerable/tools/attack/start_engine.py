import socket
import sys

TARGET_IP = "serial-bus"
PORT = 5001

def start_engine():
    print(f"[*] Sending START command (0x01) to {TARGET_IP}:{PORT}...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.sendto(b"0x01", (TARGET_IP, PORT))
        print("[+] Command sent.")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    start_engine()
