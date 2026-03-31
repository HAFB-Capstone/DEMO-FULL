import socket
import time

# Simulation Parameters
TARGET_IP = "engine-controller" # Docker DNS resolves this
PORT = 5001                     # Default port for this 1553 simulator

def send_mil_1553_word(command_hex):
    """
    Simulates sending a MIL-STD-1553 Command Word over the bus.
    The simulator expects hex strings representing the bus traffic.
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    print(f"[*] MISSION START: Injecting Command {command_hex} into Bus...")
    try:
        # We send the raw hex string that the RT's listener is waiting for
        sock.sendto(command_hex.encode(), (TARGET_IP, PORT))
        print(f"[+] Broadcast Complete. Monitoring Bus for RT Response...")
    except Exception as e:
        print(f"[!] Bus Collision/Error: {e}")

if __name__ == "__main__":
    # Let's try to 'Initialize' the engine (our hardware_stubs.py logic)
    # In a real exercise, the Red Team would have to guess or reverse-engineer this.
    send_mil_1553_word("0x01")