# VULN-Log4j

Target VM repository for the Log4Shell lab environment.

This stack exposes four services on one Docker network:

- `auth-service` on `8001`
- `inventory-service` on `8002`
- `status-service` on `8003`
- `vulnerable-app` on `8080`

`auth-service` and `inventory-service` remain the local training services. `vulnerable-app` is the christophetd sample vulnerable application, added as a known-good Log4Shell target alongside the existing lab services.

For training use only inside isolated lab environments.

## Services

| Service | Port | Source | Vulnerable |
| --- | --- | --- | --- |
| Auth Service | 8001 | Local Spring Boot app | Yes |
| Inventory Service | 8002 | Local Spring Boot app | Yes |
| Status Service | 8003 | Local Flask app | No |
| Vulnerable App | 8080 | `ghcr.io/christophetd/log4shell-vulnerable-app` | Yes |

## Administrator Controls

| Command | Description |
| --- | --- |
| `make setup` | Build the local images |
| `make up` | Start the full stack |
| `make down` | Stop the full stack |
| `make reset` | Rebuild and reset local services |
| `make logs` | Follow service logs |
| `make test` | Run health checks |

## Flag Locations

| Flag | Location | Notes |
| --- | --- | --- |
| Auth Flag | `/flags/auth_flag.txt` | Mounted into `hafb-auth` |
| Inventory Flag | `/flags/inventory_flag.txt` | Mounted into `hafb-inventory` |
| App Flag | `/flags/app_flag.txt` | Mounted into `hafb-vulnerable-app` |

## Service URLs

| Service | URL |
| --- | --- |
| Auth Service | `http://localhost:8001` |
| Inventory Service | `http://localhost:8002` |
| Status Service | `http://localhost:8003` |
| Vulnerable App | `http://localhost:8080` |

## Docker Compose

The root `docker-compose.yml` starts all four services on the existing `hafb-net` bridge network. The christophetd container mounts the shared `flags/` directory so `/flags/app_flag.txt` is available inside the container without modifying the upstream image.

Bring the stack up with:

```bash
docker compose up -d
```

Verify the added vulnerable app can read the mounted flag:

```bash
docker exec hafb-vulnerable-app ls /flags
docker exec hafb-vulnerable-app cat /flags/app_flag.txt
```

## Repository Layout

| Path | Purpose |
| --- | --- |
| `services/auth-service/` | Local vulnerable auth service |
| `services/inventory-service/` | Local vulnerable inventory service |
| `services/status-service/` | Local safe control service |
| `docker-compose.yml` | Full target stack definition |
| `flags/` | Seeded flags mounted read-only into target containers |
| `tools/test/test_services.sh` | Health check script |
| `Makefile` | Convenience commands |

## References

- [christophetd/log4shell-vulnerable-app](https://github.com/christophetd/log4shell-vulnerable-app)
- [CVE-2021-44228 - NVD](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)

For training only. Run in isolated lab environments only.
