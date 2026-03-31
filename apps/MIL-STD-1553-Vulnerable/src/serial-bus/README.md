# Serial Bus (Target Hardware)

**Role:** F-16 Engine Controller (Simulated)

**OS:** Debian Bookworm (Slim)

**Protocol:** UDP Broadcast (Simulating MIL-STD-1553)

## Overview
This container represents the "Black Box" avionics hardware. It is isolated from the host and can only be reached from the internal Docker network (`avionics-bus`). It listens for raw hex commands.

## Architecture
1.  **`mil_wrapper.py`**: A USP socket listener (Port 5001) that acts as the Bus Coupler. It takes network packets and passes them to the hardware logic.
2.  **`hardware_stubs.py`**: A state machine representing the engine.
    *   **State**: `OFF`, `IDLE`, `IGNITION`, `SHUTDOWN`.
    *   **Variables**: `RPM`, `Temp`, `OilPressure`.

## Command Dictionary (Classified)
| Hex Code | Command | Effect |
| :--- | :--- | :--- |
| `0x01` | **START_SEQ** | Spools engine to 15,000 RPM. Temps rise. |
| `0x00` | **EMERG_STOP** | Immediate cutoff. RPM drops to 0. |
| `0x02` - `0xFF` | **UNKNOWN** | Ignored by current firmware. |