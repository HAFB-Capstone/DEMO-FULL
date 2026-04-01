# SBOM-XRay (lab bundle)

Offline **software supply chain / SBOM** lab: student guide, instructor materials, optional vendored tooling under `tooling/`, and validation scripts. In **DEMO-FULL**, this app is also available as a **Docker Compose service** (`sbom-xray-lab`) so `make up` starts the lab container with the repo bind-mounted at `/lab`.

- **Start here:** [student/sbom-xray-lab-student-guide.md](student/sbom-xray-lab-student-guide.md)
- **Scenario context:** [instructor/scenario-README.md](instructor/scenario-README.md)
- **Scripts:** [install-module1-offline.sh](install-module1-offline.sh), [validate-module1-offline.sh](validate-module1-offline.sh)

## Docker workflow (root repo)

The image at [docker/Dockerfile](docker/Dockerfile) installs **Anchore Syft 1.23.1** and **jq 1.7** at **build** time (needs network for `docker compose build` / first `make up`). The running container does not download those tools again.

From the **repository root**:

```bash
make up
make sbom-shell          # interactive bash in sbom-xray-lab (or: docker compose exec sbom-xray-lab bash)
```

Stage image tars and lab files into the mount (once per clone, or after refreshing artifacts):

```bash
docker compose exec sbom-xray-lab bash -c 'SBOM_XRAY_CONTAINER=1 bash /lab/install-module1-offline.sh --lab-dir /lab'
make sbom-validate
```

Or validate directly if `flight-path-v1.tar` and `radar-control-v1.tar` are already under `/lab`:

```bash
make sbom-validate
```

The lab container uses the isolated **`sbom-lab`** Compose network (no Splunk forwarder / scenario attachment) and **no published ports** — it is a CLI environment only.

## Bare-metal / VM offline install

Use `install-module1-offline.sh` without `SBOM_XRAY_CONTAINER`; it expects pinned `tooling/syft` and `tooling/jq` in this directory. See the student guide for paths like `~/labs/sbom-xray`.

Large artifacts under `artifacts/` may require [Git LFS](https://git-lfs.github.com/); see the root README.

## Maintainer: bumping Syft or jq

Update version and `*_SHA256` args in [docker/Dockerfile](docker/Dockerfile), then adjust bands/examples per [instructor/sbom-xray-lab-toolchain-pins.md](instructor/sbom-xray-lab-toolchain-pins.md). Refresh `tooling/` and [SHA256SUMS.txt](SHA256SUMS.txt) if you still ship offline bundles.
