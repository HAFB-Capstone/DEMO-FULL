# SBOM X-Ray Lab (Module 1) — PRD §7 traceability

_Date: 2026-03-20_

This table maps **PRD acceptance criteria** ([`sbom-xray-lab-Module1-PRD.md`](./sbom-xray-lab-Module1-PRD.md) §7) to **concrete artifacts and doc sections** in this repository.

| Criterion | Requirement (summary) | Owner artifact / section |
|-----------|------------------------|---------------------------|
| **§7.A** | Offline execution; guide states assumptions and artifact locations | [`sbom-xray-lab-student-guide.md`](../sbom-xray-lab-student-guide.md) §4; [`training/scenarios/sbom-xray-lab/README.md`](../training/scenarios/sbom-xray-lab/README.md) (canonical bundle + VM copy path) |
| **§7.B** | Generate CycloneDX JSON from `.tar` | Student guide §6; staged `flight-path-v1.tar`, `radar-control-v1.tar` under `training/scenarios/sbom-xray-lab/artifacts/` (build via `build-artifacts.ps1` / `build-artifacts.sh`; `.tar` files are gitignored) |
| **§7.C** | Navigate metadata, timestamp, supplier/creator; locate component + PURL | Student guide §§6–7; instructor key in [`sbom-xray-lab-Module1-instructor.md`](./sbom-xray-lab-Module1-instructor.md) |
| **§7.D** | Compare CDX vs SPDX counts and metadata | Student guide §7; `vendor_claim.spdx.json` |
| **§7.E** | Direct vs transitive via relationships | Student guide §8 (Python `requests` → `urllib3` example aligned to images) |
| **§7.F** | Two apps; PURL intersection; blast-radius narrative | Student guide §9; `radar-control-v1.tar` **required** |
| **§7.G** | Minimum-elements critique; ≥3 vendor deficiencies; ≥1 known-unknown marker | [`SBOM_Minimum_Elements.md`](../training/scenarios/sbom-xray-lab/artifacts/SBOM_Minimum_Elements.md); student guide §§10–11; instructor exemplar critique |
| **§7.H** | Scavenger hunt + short ISSO/ISSM critique memo | Student guide §§11–11a; rubric + answer key in instructor packet |

### VM role and path

- **Target role:** Blue Team / analysis VM (offline).
- **Lab path on VM:** `~/labs/sbom-xray/` — populated by Ansible or manual copy from the **`training/scenarios/sbom-xray-lab/artifacts/`** bundle (see scenario README).

### Artifact delivery mechanism (decision)

- **Canonical in-repo location:** `training/scenarios/sbom-xray-lab/` (Docker sources + `artifacts/` JSON/checklist; image `.tar` files built locally and distributed out-of-band or via org tarball).
- **Future:** May be mirrored under an org-wide `training/scenarios/` repo per [`sbom-xray-lab-agent-brief.md`](../sbom-xray-lab-agent-brief.md) §9.

### Tool pins (summary)

Documented in detail in [`sbom-xray-lab-toolchain-pins.md`](./sbom-xray-lab-toolchain-pins.md).
