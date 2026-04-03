# Lab Setup - Two VM Testing Guide

How to test the RT-Log4j attacker stack against a vulnerable VM before moving into a larger lab.

---

## Option A - VirtualBox / VMware

### Step 1 - Create the vulnerable VM

1. Build or import the vulnerable environment.
2. Start its services and confirm it exposes ports `8001`, `8002`, and `8003`.
3. Note the VM IP with `ip a`.

### Step 2 - Prepare the attacker host

1. Clone this repository onto the attacker machine.
2. Ensure Docker is installed.
3. Run:

```bash
cd RT-Log4j
bash setup/configure.sh
make build
make up
make shell
```

### Step 3 - Verify networking

Both systems must be on the same reachable network.

From the attacker host:

```bash
ping <target-ip>
curl http://<target-ip>:8001
```

### Step 4 - Run tools from the container

Inside the attacker container:

```bash
python3 tools/recon/nmap_scan.py
python3 tools/exploit/log4shell_recon.py --scan
python3 tools/exploit/log4shell_exploit.py
```

---

## Option B - Single-host Docker testing

If the vulnerable environment runs on the same machine, point the RT config at `127.0.0.1`:

```bash
cd RT-Log4j
TARGET_HOST=127.0.0.1 bash setup/configure.sh
make up
make shell
```

Inside the container:

```bash
python3 tools/recon/nmap_scan.py --host 127.0.0.1
```

---

## Option C - Proxmox or classroom lab

1. Coordinate with the vulnerable-service team for the target VM IP.
2. Load or build the attacker image on the student or operator machine.
3. Run `bash setup/configure.sh`.
4. Start the container with `make up`.
5. Enter the shell with `make shell`.

---

## Airgapped delivery

### Instructor machine

```bash
cd RT-Log4j
make build
make save
```

Carry `rt-log4j-attacker.tar` and the repository to the disconnected machine.

### Student machine

```bash
docker load < rt-log4j-attacker.tar
cd RT-Log4j
bash setup/configure.sh
make up
make shell
```

---

## Troubleshooting

**Cannot reach the target**
- Confirm the target IP in `config/target.yaml`.
- Confirm the vulnerable services are listening on `8001`, `8002`, or `8003`.
- Confirm the attacker host and target VM are on the same network.

**Container shell fails**
- Run `make up` first.
- Check `docker compose ps` for the `attacker` container state.

**Config needs to be regenerated**
- Re-run `bash setup/configure.sh` from the repo root.

**Loot is missing after restart**
- Check the host `loot/` directory. It is mounted into the container and should persist there.
