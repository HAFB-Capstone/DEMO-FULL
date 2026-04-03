# Attacker Toolkit (Red Team)

This directory contains resources for sample Red Team engagement.

## Structure
*   `attack/`: Contains the python scripts and payloads used to interact with the target. Includes a Dockerfile to build an isolated attacker container.
*   `test/`: Automated verification scripts to ensure the environment is functioning correctly.

## Automated Testing
You can run the full verification suite using:
```bash
make test
```
