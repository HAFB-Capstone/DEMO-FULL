# SBOM X-Ray Lab (Module 1) — pinned toolchain

These versions are the **authoritative targets** for reproducible CycloneDX output and documented `jq` paths. The training VM image should install the same **major.minor** (or exact) versions where practical.

| Tool | Pinned reference | Notes |
|------|------------------|--------|
| **Syft** | `anchore/syft:v1.23.1` (OCI image) or Syft binary **1.23.1** | Used to author expected component counts and metadata shape. |
| **jq** | **1.7** (or distro-packaged 1.6+ with `walk` support) | Student guide uses basic filters only. |
| **OS** | Debian **12** (bookworm) userspace in lab images | Matches `python:…-slim-bookworm` base. |
| **Container base** | `python:3.12.8-slim-bookworm@sha256:2199a62885a12290dc9c5be3ca0681d367576ab7bf037da120e564723292a2f0` | Declared in Dockerfiles under `training/scenarios/sbom-xray-lab/docker/`. |

### When bumping Syft

1. Re-run `scripts/verify_sbom_xray_lab.py --full` (or `scripts/test.ps1 -Full`) on a machine with Docker.
2. Update **expected ranges** in `training/scenarios/sbom-xray-lab/expected_outputs.json` if component counts shift materially.
3. Re-validate **every** `jq` example in `sbom-xray-lab-student-guide.md`.
4. Record the change in `aiDocs/changelog.md`.
