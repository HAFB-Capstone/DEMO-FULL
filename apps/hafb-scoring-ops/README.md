# HAFB Scoring Ops

`hafb-scoring-ops` is an internal health and scoring dashboard for the Hill AFB capstone lab. It is intended to run on the `controlOps` VM and provide a concise operational view of monitored lab services through a simple, explainable scoring model.

The application exposes:

- a web dashboard for evaluators and operators
- a backend monitoring loop that can run live endpoint checks
- a deterministic demo mode for presentation and verification
- a configuration-driven method for adding additional monitored services

## Overview

The dashboard tracks vulnerability families rather than presenting a large inventory wall. Each family contains one or more HTTP endpoints. During monitoring, the backend tests those endpoints from `controlOps` and calculates:

- a family score from `0` to `100`
- an overall dashboard score from `0` to `100`
- per-endpoint status, response code, and latency when available

The current tracked families are:

- `Log4j-Vulnerable`
- `MIL-STD-1553-Vulnerable`

## Repository Layout

- `app/main.py` — FastAPI application and HTTP routes
- `app/state.py` — in-memory dashboard controller and monitor lifecycle
- `app/services/availability.py` — live probes and deterministic demo responses
- `config/availability_targets.json` — monitored families and endpoints
- `templates/` — server-rendered HTML
- `static/` — client-side JavaScript and CSS
- `scripts/setup_dashboard.sh` — virtualenv setup
- `scripts/run_dashboard.sh` — dashboard launch script

## Docker Compose (DEMO-FULL monorepo)

When this app lives under `DEMO-FULL/apps/hafb-scoring-ops`, the root [`docker-compose.yaml`](../../docker-compose.yaml) builds and runs the `scoring-ops` service on **host port 8090** (container port 8080). It joins the same Docker networks as the Log4j and MIL-STD-1553 stacks; [`config/availability_targets.json`](config/availability_targets.json) uses Compose **service DNS names** (for example `http://log4j-auth-service:8001/health`).

For a detached **controlOps** VM deployment, replace those URLs with internal lab hostnames (for example `http://ubuntuVictim:8101/health`) and restart the dashboard.

## Quick Start

On `controlOps`:

```bash
cd ~/hafb-scoring-ops
./scripts/setup_dashboard.sh
HOST=0.0.0.0 PORT=8080 ./scripts/run_dashboard.sh
```

Access the dashboard:

- locally on the VM: [http://127.0.0.1:8080](http://127.0.0.1:8080)
- from another internal lab host: `http://<controlOps-ip>:8080`

Health check:

```bash
curl http://127.0.0.1:8080/healthz
```

Expected response:

```json
{"status":"ok"}
```

If the VM uses UFW:

```bash
sudo ufw allow 8080/tcp
```

## Dashboard Operation

The dashboard provides three operator actions:

- `Start` — begins live endpoint checks from `controlOps`
- `Demo` — begins deterministic simulated checks for presentation or verification
- `Stop` — halts the monitor loop and preserves the last score

Equivalent API calls:

```bash
curl -X POST http://127.0.0.1:8080/api/monitor/start
curl -X POST http://127.0.0.1:8080/api/monitor/demo
curl -X POST http://127.0.0.1:8080/api/monitor/stop
curl http://127.0.0.1:8080/api/state
```

## Scoring Model

The scoring model is intentionally simple and deterministic.

- Each vulnerability family contains one or more HTTP checks.
- A check is considered healthy only when it returns HTTP `200`.
- Family score:
  - `round((healthy_checks / total_checks) * 100)`
- Overall dashboard score:
  - arithmetic mean of all family scores

This keeps the score transparent during evaluation and easy to verify during testing.

## Availability Configuration

Monitored endpoints are defined in [config/availability_targets.json](config/availability_targets.json).

Current live checks:

- `http://ubuntuVictim:8101/health`
- `http://ubuntuVictim:8102/health`
- `http://ubuntuVictim:9080/`

Each family entry contains:

- `name` — label rendered in the dashboard
- `checks` — list of individual endpoints
- for each check:
  - `id` — stable identifier used by the backend
  - `name` — operator-facing label
  - `url` — internal endpoint probed from `controlOps`

## Adding Monitored Services

To add additional services or vulnerability families:

1. Edit [config/availability_targets.json](config/availability_targets.json).
2. Add a new check to an existing family, or add a new family object.
3. Restart the dashboard.
4. Use `Start` to validate the live endpoint checks.

Example: add a new endpoint to `Log4j-Vulnerable`

```json
{
  "name": "Log4j-Vulnerable",
  "checks": [
    {
      "id": "log4j-auth-health",
      "name": "Auth Service",
      "url": "http://ubuntuVictim:8101/health"
    },
    {
      "id": "log4j-inventory-health",
      "name": "Inventory Service",
      "url": "http://ubuntuVictim:8102/health"
    },
    {
      "id": "log4j-status-health",
      "name": "Status Service",
      "url": "http://ubuntuVictim:8103/health"
    }
  ]
}
```

Example: add a new family

```json
{
  "name": "New-Vulnerability-Family",
  "checks": [
    {
      "id": "new-service-health",
      "name": "New Service",
      "url": "http://ubuntuVictim:9001/health"
    }
  ]
}
```

Notes:

- No frontend change is required when adding checks or families. The dashboard renders from configuration.
- The current monitor supports HTTP `GET` checks only.
- For non-HTTP services, the recommended pattern is to expose a small internal health endpoint or proxy a health result through an internal API.

## Air-Gapped Deployment

This application is designed for an internal-only lab environment.

- the browser communicates only with the dashboard service on `controlOps`
- live checks target internal lab endpoints only
- there is no runtime dependency on external internet services

Python dependency installation can also be staged offline. The setup scripts prefer a local wheelhouse at `vendor/wheels` or the path defined in `HAFB_PYTHON_WHEELHOUSE`.

Prepare wheels on a connected staging machine:

```bash
cd /path/to/hafb-scoring-ops
python3 -m pip download -r requirements.txt -d vendor/wheels
```

Then copy the repository, including `vendor/wheels`, to `controlOps` and run the normal setup script.

## Verification

Compile check:

```bash
python3 -m py_compile app/*.py app/services/*.py
```

Manual API verification:

```bash
curl http://127.0.0.1:8080/api/state | python3 -m json.tool | sed -n '1,120p'
```

Recommended smoke tests:

1. Launch the dashboard.
2. Click `Demo` and confirm the timer starts and endpoint states populate.
3. Click `Stop` and confirm the timer freezes.
4. When target services are available, click `Start` and confirm live status is returned from internal endpoints.
