# RT-Log4j

Red team training module for CVE-2021-44228 (Log4Shell), packaged around a Docker-based attacker workstation so the repo can operate fully airgapped after the image is built once.

For training use only inside isolated lab environments.

## Objective

Use the attacker container to:

1. Identify candidate services with recon and canary probing.
2. Exploit confirmed Log4Shell targets.
3. Capture loot and demonstrate impact inside the lab.

## Repository Structure

```text
RT-Log4j/
  docker/
    attacker/
      Dockerfile
  tools/
    exploit/
      log4shell_recon.py
      log4shell_exploit.py
    recon/
      nmap_scan.py
  config/
    target.yaml
  setup/
    configure.sh
  docker-compose.yml
  Makefile
```

## Quick Start

### Internet-connected build host

```bash
git clone <repo-url>
cd RT-Log4j
bash setup/configure.sh
make build
make up
start http://localhost:8000
make shell
```

Inside the attacker container:

```bash
python3 tools/recon/nmap_scan.py
python3 tools/exploit/log4shell_recon.py --scan
python3 tools/exploit/log4shell_exploit.py
```

### Airgapped host after the image exists

```bash
docker load < rt-log4j-attacker.tar
cd RT-Log4j
bash setup/configure.sh
make up
start http://localhost:8000
make shell
```

## Docker Architecture

The attacker image is built from `docker/attacker/Dockerfile` and bakes in:

- OpenJDK 8
- Python 3 and `pip`
- `nmap`, `netcat`, `curl`, `wget`, `git`, `maven`, `unzip`, `net-tools`
- `marshalsec`, cloned and built during image build
- `JNDIExploit`, downloaded during image build from the Wayback Machine
- Python packages from `requirements.txt`

`docker-compose.yml` runs a long-lived `attacker` container, mounts `tools/`, `config/`, `loot/`, and `logs/`, and uses host networking so the container can reach lab services and bind listeners without extra rebuilds. It also serves the training UI from `docs/training-ui/` through an `nginx:alpine` container on `http://localhost:8000`.

## Configuration

`setup/configure.sh` does environment configuration only:

- auto-detects the attacker/Kali IP
- prompts for the target VM IP
- writes both values to `config/target.yaml`
- verifies target reachability with ICMP first and TCP fallback second
- prints the next Docker steps

The config file structure remains:

```yaml
target:
  host: "192.168.x.x"

attacker:
  host: "192.168.x.x"
  port: 9999
```

## Services

The vulnerable lab typically exposes:

| Service | Port | Expected role |
| --- | --- | --- |
| auth-service | 8001 | Java service |
| inventory-service | 8002 | Java service |
| status-service | 8003 | Non-vulnerable reference service |

The attacker container reaches those services through the target IP written to `config/target.yaml`.

## Commands

| Command | Description |
| --- | --- |
| `bash setup/configure.sh` | Configure target and attacker IPs |
| `make build` | Build the attacker image |
| `make up` | Start the attacker container and training UI |
| `make down` | Stop the attacker container and training UI |
| `make shell` | Open a shell inside the attacker container |
| `make save` | Save the attacker image to `rt-log4j-attacker.tar` |
| `make load` | Load the attacker image from `rt-log4j-attacker.tar` |
| `http://localhost:8000` | Open the training UI in your browser |
| `python3 tools/recon/nmap_scan.py` | Run recon from inside the container |
| `python3 tools/exploit/log4shell_recon.py --scan` | Run JNDI canary probing from inside the container |
| `python3 tools/exploit/log4shell_exploit.py` | Run the exploit flow from inside the container |

## Airgapped Distribution Flow

### Instructor workflow

```bash
cd RT-Log4j
make build
make save
```

This produces `rt-log4j-attacker.tar`.

### Student workflow

```bash
docker load < rt-log4j-attacker.tar
cd RT-Log4j
bash setup/configure.sh
make up
start http://localhost:8000
make shell
```

At that point the attacker container and training UI are ready without downloading any additional tooling.

## Notes

- No binary tooling is committed in the repo anymore.
- `setup/install.sh` has been retired in favor of the Docker image plus `setup/configure.sh`.
- `tools/exploit/log4shell_recon.py` and `tools/exploit/log4shell_exploit.py` remain in place as the active exploit tooling.
