# SBOM X-Ray Lab (Module 1) — scenario bundle

Offline-first SBOM literacy lab: **generate CycloneDX** from container archives, **navigate JSON**, **compare** to a vendor **SPDX** claim, **intersect PURLs** across two apps, and **critique** quality using minimum-elements thinking.

## Canonical layout (this repo)

| Path | Purpose |
|------|---------|
| `docker/flight-path/` | Dockerfile for `flight-path-v1` training image |
| `docker/radar-control/` | Dockerfile for `radar-control-v1` (shared-deps overlap) |
| `artifacts/` | Staged **offline** files: SPDX claim, checklist, image payloads as **`.tar.gz`** in git (under GitHub’s 100 MB limit); optional local **`.tar`** from `build-artifacts.*` |
| `expected_outputs.json` | Ranges and exemplar PURLs used by `scripts/verify_sbom_xray_lab.py` |

## Deployment copy on the lab VM

Ansible or facilitators should mirror this folder to:

`~/labs/sbom-xray/`

Expected files visible to students (after `install-module1-offline.sh`, which decompresses `artifacts/*.tar.gz` into the lab folder):

- `flight-path-v1.tar`
- `radar-control-v1.tar` (**required** for PRD shared-PURL objective)
- `vendor_claim.spdx.json`
- `SBOM_Minimum_Elements.md`
- Student guide (copy from repo root `sbom-xray-lab-student-guide.md` or your LMS)
- Student worksheet (`sbom-xray-lab-student-worksheet.md`)

## Building image archives

From this directory:

**PowerShell (Windows):**

```powershell
./build-artifacts.ps1
```

**Bash (Linux / Git Bash):**

```bash
./build-artifacts.sh
```

Then compute SHA-256 for your release notes (example):

```bash
sha256sum artifacts/flight-path-v1.tar.gz artifacts/radar-control-v1.tar.gz
# or, for uncompressed local builds:
# sha256sum artifacts/flight-path-v1.tar artifacts/radar-control-v1.tar
```

## Tooling

See [`docs/sbom-xray-lab-toolchain-pins.md`](../../../docs/sbom-xray-lab-toolchain-pins.md).

## Verification

From repo root:

```bash
python scripts/verify_sbom_xray_lab.py
```

Full check (Docker + Syft OCI image + optional tar scan):

```bash
python scripts/verify_sbom_xray_lab.py --full
```

## Instructor materials

- [`docs/sbom-xray-lab-Module1-instructor.md`](../../../docs/sbom-xray-lab-Module1-instructor.md) — timing, rubric, answer key, troubleshooting
- [`docs/sbom-xray-lab-Module1-prd-traceability.md`](../../../docs/sbom-xray-lab-Module1-prd-traceability.md) — PRD §7 mapping
