import socket
import time

TARGET_IP = "serial-bus"
PORT = 5001

def fuzz():
    print(f"[*] Fuzzing BUS at {TARGET_IP}:{PORT} (0x00 - 0xFF)...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    for i in range(256):
        hex_cmd = f"0x{i:02x}"
        try:
            sock.sendto(hex_cmd.encode(), (TARGET_IP, PORT))
            print(f"[>] Sent {hex_cmd}", end='\r')
            time.sleep(0.05)
        except Exception as e:
            print(f"[-] Error: {e}")
            break
            
    print("\n[+] Fuzzing complete.")

if __name__ == "__main__":
    fuzz()
