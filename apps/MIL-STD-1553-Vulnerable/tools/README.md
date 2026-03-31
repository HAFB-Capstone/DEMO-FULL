# Attacker Toolkit (Red Team)

This directory contains resources for the Red Team engagement.

## Structure
*   `attack/`: Contains the python scripts and `attack_payload.sh` used to interact with the avionics bus. Includes a Dockerfile to build an isolated attacker container.
*   `test/`: Automated verification scripts to ensure the environment is functioning correctly.

## automated Testing
You can run the full verification suite using:
```bash
make test
```

## The Scripts

### `start_engine.py`
Sends the `0x01` command to the Serial Bus.
```bash
python3 start_engine.py
```

### `kill_engine.py`
Sends the `0x00` command. Useful for "Safety Verification".
```bash
python3 kill_engine.py
```

### `fuzz_bus.py`
Sends a sequence of bytes from `0x00` to `0xFF` to discover hidden hardware commands.
```bash
python3 fuzz_bus.py
```
