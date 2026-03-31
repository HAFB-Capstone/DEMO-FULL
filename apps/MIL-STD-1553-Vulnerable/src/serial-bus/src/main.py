import sys
import os

# Essential Paths
sys.path.append('/app/src')

try:
    from mil_wrapper import FlightHardware
    print("[SYSTEM] AVIONICS OS LOADED")
except ImportError as e:
    print(f"[SYSTEM] FATAL ERROR: {e}")
    sys.exit(1)

if __name__ == "__main__":
    print("--- AF FLIGHT COMPUTER v1.0 (SIMULATED) ---")
    try:
        # Initializing RT 01
        engine = FlightHardware(rt_address=1)
        engine.listen_forever()
    except Exception as e:
        print(f"[FATAL] HARDWARE FAILURE: {e}")