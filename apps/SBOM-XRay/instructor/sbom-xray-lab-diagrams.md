# SBOM X-Ray Lab (Module 1) - Diagrams

These diagrams are ASCII-first for reliable rendering in any editor/terminal.

---

## 1) Program Fit Diagram (Where Module 1 sits)

```text
HAFB / 309th SWEG SBOM Training Track
=====================================

  [Module 1]
  SBOM X-Ray Lab (FOUNDATION)
      |
      |-- teaches: generate SBOM, compare CycloneDX vs SPDX,
      |            dependency reasoning, shared-risk, quality critique
      v
  [Module 2]
  Vuln Dispatch (IR mapping / triage)
      v
  [Module 3]
  Supply-Chain Whodunit (forensic diffing / integrity)
      v
  [Later Governance Modules]
  Policy, EOL, Provenance, Procurement

Core Idea:
Module 1 builds SBOM literacy first so later modules can assume
students can read and trust-check SBOM artifacts.
```

---

## 2) Lab Run Flow Diagram (Student execution flow)

```text
SBOM X-Ray Lab - Student Flow
=============================

 [Start: Offline VM + Pre-staged Artifacts]
                    |
                    v
      +-----------------------------+
      | Generate internal CycloneDX |
      | syft ... > internal_cdx.json|
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Navigate SBOM structure     |
      | metadata/components/deps    |
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Compare with vendor SPDX    |
      | vendor_claim.spdx.json      |
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Dependency reasoning        |
      | direct vs transitive        |
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Shared dependency analysis  |
      | app A vs app B (PURLs)      |
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Minimum-elements critique   |
      | + known unknowns (NOASSERT) |
      +-----------------------------+
                    |
                    v
      +-----------------------------+
      | Outputs                     |
      | - scavenger answers         |
      | - critique memo             |
      | - ISSO/ISSM risk summary    |
      +-----------------------------+
```

---

## 3) Air-Gapped Artifact and Data Flow Diagram

```text
Air-Gapped SBOM X-Ray Data Flow
===============================

   (Pre-staged on Blue Team VM / analysis VM)
   ------------------------------------------
   flight-path-v1.tar
   radar-control-v1.tar
   vendor_claim.spdx.json
   SBOM_Minimum_Elements.md (or PDF)
   syft, jq, shell utils
            |
            v
   +---------------------+
   | syft (offline only) |
   +---------------------+
            |
            v
   internal_cdx.json    radar_cdx.json
            |                 |
            +--------+--------+
                     |
                     v
            +------------------+
            | jq + shell tools |
            | (sort/comm/etc.) |
            +------------------+
                     |
    +----------------+----------------------+
    |                |                      |
    v                v                      v
 Compare CDX     Shared PURL set      Quality checklist
 vs vendor SPDX  intersection          (min elements +
                                      known unknowns)
    \                |                      /
     \               |                     /
      +--------------+--------------------+
                     |
                     v
         Student findings + critique memo
         + short ISSO/ISSM risk summary
```

---

## 4) VM + Container Topology for Module 1 (SBOM Training Module)

```text
Proxmox Host (air-gapped lab)
=============================

  +---------------------------------------------------------------+
  | VM: Ansible Controller (optional for prep/deploy)             |
  | - Stages lab artifacts to analysis VM(s)                      |
  | - Does not need to run training containers during class       |
  +---------------------------------------------------------------+

  +---------------------------------------------------------------+
  | VM: Blue Team / Analysis VM (primary student VM for Module 1) |
  |                                                               |
  |  Tools on VM: syft, jq, sort, comm, less                      |
  |  Lab folder: ~/labs/sbom-xray/                                |
  |                                                               |
  |  Pre-staged image archives (not running):                     |
  |   - flight-path-v1.tar                                        |
  |   - radar-control-v1.tar                                      |
  |                                                               |
  |  Optional local runtime (if instructor chooses):              |
  |   docker load < flight-path-v1.tar                            |
  |   docker load < radar-control-v1.tar                          |
  |                                                               |
  |  Generated outputs by student:                                |
  |   - internal_cdx.json                                         |
  |   - radar_cdx.json                                            |
  |   - shared-purls.txt                                          |
  |   - critique-memo.md                                          |
  +---------------------------------------------------------------+

  +---------------------------------------------------------------+
  | VM: Victim / Red Team VMs (not required for core Module 1)    |
  | - May exist in broader environment                             |
  | - Not required to complete SBOM X-Ray learning objectives      |
  +---------------------------------------------------------------+
```

### Containers that need to exist (minimum)

```text
Required for Module 1:
- 2 container IMAGE ARCHIVES available on Blue/Analysis VM:
  1) flight-path-v1.tar
  2) radar-control-v1.tar (for shared dependency analysis)

Not strictly required:
- Running container instances (docker run ...) are optional.
  Syft can scan docker-archive tar files directly.

Also required:
- vendor_claim.spdx.json (vendor SBOM to critique)
- SBOM minimum-elements checklist doc (md/pdf)
```

---

## 5) Typical Student Timeline (Module 1)

```text
1) Student starts on the Blue/Analysis VM
   - Confirms offline lab directory exists (~/labs/sbom-xray)
   - Verifies required files/tools are present (tar files, SPDX file, syft, jq)

2) Student does NOT need to start app containers to begin
   - Uses image archives directly for SBOM generation
   - (Optional) instructor may have students docker load/run for context, but not required

3) Student uses Syft to generate internal SBOM for Flight Path
   - Input: flight-path-v1.tar
   - Output: internal_cdx.json

4) Student uses jq to inspect metadata/components/dependencies
   - Finds supplier/creator fields, timestamps, tool info
   - Locates selected libraries and identifiers (PURLs)

5) Student compares internal CycloneDX with vendor SPDX
   - Input: internal_cdx.json vs vendor_claim.spdx.json
   - Tasks: component/package counts, field mapping, visible gaps

6) Student generates SBOM for second app
   - Input: radar-control-v1.tar
   - Output: radar_cdx.json

7) Student computes shared dependency intersection
   - Extracts/sorts PURLs from both CDX files
   - Produces shared-purls.txt
   - Explains blast-radius implication

8) Student performs minimum-elements critique
   - Uses local checklist (CISA/NTIA-aligned)
   - Identifies concrete deficiencies and known unknowns (e.g., NOASSERTION)

9) Student submits outputs
   - Scavenger-hunt answers
   - Short critique memo
   - 2-3 sentence ISSO/ISSM risk summary
```

