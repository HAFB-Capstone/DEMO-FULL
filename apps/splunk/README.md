# BT-Splunk (Blue Team)

Splunk Enterprise image build, analytics (rules + dashboards), Universal Forwarder payloads, and deployment scripts. In **DEMO-FULL**, Splunk is started by the **repository root** [`docker-compose.yaml`](../../docker-compose.yaml): service `splunk` (web UI on host **9000**, management **9089**, ingest **9997**) and `splunk-payloads` (installers on **8001**).

## Quick commands (monorepo root)

| Goal | Command |
|------|---------|
| Prepare UF packages | `make setup` (runs `setup_host.sh` with `SKIP_SERVE=1`) |
| Start full stack | `make up` |
| Splunk health | `make validate` |
| Logs | `make logs-splunk` |

## Forwarder on Linux targets

From each target:

```bash
curl -O http://<BLUE_HOST>:8001/deploy_splunk_forwarder.sh
sudo bash deploy_splunk_forwarder.sh <BLUE_HOST> <BLUE_HOST>
```

Targets need reachability to Splunk on **9089** and **9997** on the host running Docker.

## Layout

| Path | Purpose |
|------|---------|
| `config/Dockerfile` | Custom Splunk image (from `splunk/splunk`) |
| `config/ansible.cfg` | Ansible tweaks inside the image |
| `deployment/serve.py` | HTTP server for payloads (`PAYLOAD_SERVER_PORT`, `PAYLOAD_SERVER_DIR`) |
| `deployment/deploy_splunk_forwarder.sh` | Run on targets to install/configure UF |
| `deployment/payloads/` | `.deb` / `.rpm` forwarder packages + `version.txt` (from `setup_host.sh`) |
| `analytics/rules/` | Saved searches / rules (mounted read-only) |
| `analytics/dashboards/` | XML views (mounted read-only) |
| `setup_host.sh` | Creates `apps/splunk/.env` if missing, downloads payloads; with `SKIP_SERVE=1` skips foreground HTTP server |
| `validation/validate_splunk.py` | Host-side API check; set `SPLUNK_MGMT_BASE` (e.g. `https://localhost:9089`) and `SPLUNK_PASSWORD` |

## Standalone Splunk-only workflow (optional)

From the **repository root**:

```bash
docker compose up -d splunk splunk-payloads
```

Prepare forwarder packages with `make setup` (or `cd apps/splunk && SKIP_SERVE=1 bash setup_host.sh`). To run the payload HTTP server on your host instead of the container, use `python3 deployment/serve.py` from `apps/splunk` in a second terminal (still uses port **8001** by default—stop `splunk-payloads` first if it would conflict).
