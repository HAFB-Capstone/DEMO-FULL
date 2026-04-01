# SBOM X-Ray Lab (Module 1) — instructor & facilitation packet

_Date: 2026-03-20_

**Related:** [PRD](./sbom-xray-lab-Module1-PRD.md) · [Plan](./sbom-xray-lab-Module1-plan.md) · [Tool pins](./sbom-xray-lab-toolchain-pins.md) · [PRD traceability](./sbom-xray-lab-Module1-prd-traceability.md) · [Scenario README](../training/scenarios/sbom-xray-lab/README.md)

---

## 1. Timing guide (≈ 90–120 minutes)

| Block | Duration | Focus |
|-------|----------|--------|
| Intro & scenario | 10–15 min | Role (software assurance), why SBOMs matter offline, CycloneDX vs SPDX at a glance |
| Part 1 — generate internal SBOM | 15–20 min | `syft` → `internal_cdx.json`, metadata orientation |
| Part 2 — format compare | 15–20 min | Counts, creator/supplier, vendor vs internal |
| Part 3 — dependencies | 15–20 min | Direct vs transitive using Python ecosystem examples |
| Part 4 — shared PURLs | 15–20 min | Second image, `sort` + `comm`, blast-radius discussion |
| Part 5 — minimum elements | 10–15 min | Checklist mapping for both SBOMs |
| Scavenger hunt | 15–20 min | Time-boxed teams |
| Critique memo + debrief | 10–15 min | ISSO-style summary, lessons learned |

Adjust depth for cohort experience; **do not skip** the second image (PRD §7.F).

---

## 2. Rubric (0–5 scale)

Use for **scavenger hunt** items and the **critique memo** (student guide §11a).

| Score | Meaning |
|-------|---------|
| 0–1 | Wrong artifact, wrong format, or no evidence from JSON |
| 2–3 | Factually correct but shallow (“counts differ”) with no risk implication |
| 4–5 | Correct **and** ties to operations (incident, acquisition, patch priority) |

**Weights (suggested):** 60% scavenger accuracy, 40% critique memo quality.

---

## 3. Answer key (pinned Syft **1.23.1**, current training images)

> Values below assume images built from `training/scenarios/sbom-xray-lab/docker/` with the **pinned** `python:3.12.8-slim-bookworm` digest in those Dockerfiles. Rebuilding without the digest may shift counts slightly—use `python scripts/verify_sbom_xray_lab.py --full` after changes.

### 3.1 Scavenger hunt (student guide §11)

1. **Primary web framework PURL (Flight Path):** `pkg:pypi/flask@3.0.0`
2. **Total components (internal CycloneDX for Flight Path):** **3362** (expect **3000–4000** if base layers change; see `expected_outputs.json`)
3. **Transitive dependency example:** e.g. **`urllib3`** is depended on by **`requests`** (see `dependencies` where `ref` is the requests bom-ref / PURL and `dependsOn` lists urllib3). **Flask** is a **direct** pip install; **requests** is also direct; **urllib3** is **transitive** via requests.
4. **Two shared components (examples):** e.g. `pkg:pypi/requests@2.31.0` and `pkg:pypi/urllib3@2.6.3` (many `pkg:deb/debian/...` OS packages are also shared—accept any two correct PURLs from `shared-purls.txt`)
5. **Vendor SPDX hashes:** **No** `checksums` blocks on packages in `vendor_claim.spdx.json` — this is an intentional **minimum-elements gap**. Internal CycloneDX from Syft includes hashes for many cataloged components.
6. **Earliest timestamp:** Vendor `creationInfo.created` is **2024-06-01T12:00:00Z** (stale vs actual class date—talk about **freshness**). Internal SBOM `metadata.timestamp` reflects **scan time** (when Syft ran).
7. **Shared dependency blast radius:** If a CVE hits e.g. **`pkg:pypi/urllib3@2.6.3`**, **both Flight Path and Radar Control** are in scope.

### 3.2 Part 1 worksheet prompts (supplier / tool)

- **Supplier:** Syft’s CycloneDX for these images typically **does not** populate `.metadata.supplier`; the **container name** appears under `metadata.component`. Students should record **absence** and contrast with vendor SPDX (which uses **`NOASSERTION`** in multiple fields).
- **Tool:** `jq '.metadata.tools' internal_cdx.json` — expect **syft** **1.23.1** when using the pinned toolchain.

### 3.3 Counts snapshot

| Artifact | Metric | Representative value |
|----------|--------|----------------------|
| `internal_cdx.json` | `jq '.components \| length'` | **3362** |
| `radar_cdx.json` | `jq '.components \| length'` | **3351** |
| `vendor_claim.spdx.json` | `jq '.packages \| length'` | **9** |

### 3.4 PRD §7.G — exemplar vendor deficiencies (≥3)

Accept any **specific, evidence-based** answers; model answers:

1. **Incomplete inventory:** only **9** SPDX packages vs **thousands** of components in the internal SBOM (OS + Python graph)—vendor claim is not comprehensive for the delivered image.
2. **Missing integrity evidence:** packages lack **checksums** while internal SBOM includes hashes for many components—harder to detect tampering or verify provenance.
3. **Thin dependency graph:** only **3** `relationships` and no `DEPENDS_ON` edges for transitive Python deps—does not support impact analysis the way CycloneDX `dependencies` does.
4. **Explicit unknowns without remediation:** widespread **`NOASSERTION`** for `supplier`, `licenseConcluded`, and `downloadLocation`—students should explain this is **declared ignorance**, not the same as a detailed field left blank elsewhere.

### 3.5 PRD §7.G — known unknown marker

- Point to any **`NOASSERTION`** in `vendor_claim.spdx.json` (e.g. `downloadLocation`, `supplier`, `licenseConcluded`).
- **Good student answer:** SPDX is **explicitly marking unknown**; risk is you **cannot** automate policy or contact-the-supplier workflows without follow-up.

---

## 4. Troubleshooting

| Symptom | Likely cause | Facilitator action |
|---------|--------------|-------------------|
| `comm -12` shows nothing | Unsorted inputs or empty PURL lines | Ensure `sort` ran; check for `null` lines from `jq -r` (filter empty) |
| Huge `internal_cdx.json` | Full OS catalog | Normal; use `less`, `jq` filters, and time limits |
| `jq` errors on `.metadata.supplier` | Field absent | Teach **null / absent** as a first-class outcome |
| Syft errors on `.tar` | Wrong path or corrupt archive | `ls -l` the tar; re-copy from bundle; rebuild with `build-artifacts.*` |
| Different component counts after upgrade | Syft/cataloger change | Re-run `verify_sbom_xray_lab.py --full`; update `expected_outputs.json` |

**Optional `jq` hygiene for null PURLs:**

```bash
jq -r '.components[].purl | select(. != null)' internal_cdx.json > flight-path-purls.txt
```

**Large files:** `less internal_cdx.json` then `/metadata` to search; prefer `jq` for structure.

---

## 5. Packaging & pilot checklist (air-gapped)

- [ ] VM has **`syft`** and **`jq`** on `PATH` (versions per [tool pins](./sbom-xray-lab-toolchain-pins.md)).
- [ ] `~/labs/sbom-xray/` contains **both** tars, vendor SPDX, checklist, student guide.
- [ ] Disable egress or confirm **no** `docker pull` / registry use **during** the lab.
- [ ] Facilitator dry-run: run student commands verbatim once per release.

---

## 6. Handoff to later modules (non-blocking)

- **Module 2+ reuse:** PURL intersection and “shared library = shared blast radius” carry directly into vuln mapping and diff labs.
- **Explicit deferrals:** live NVD feeds, VEX, SLSA attestation, automated policy gates—out of scope for Module 1; mention by name only to avoid scope creep.

---

## 7. Reference checksums (maintainer build, 2026-03-20)

These match `expected_outputs.json` for the recorded build:

| File | SHA-256 |
|------|---------|
| `flight-path-v1.tar` | `29b65d1e746923fc22c5b7d7438fbac035a75a93e9536195b28cb2249c9015ba` |
| `radar-control-v1.tar` | `dd810bf26b583b6baddc5b7997a4fa3fe583cb7c9b930bdec294b85bf739621a` |

Re-release images → recompute hashes and update **both** this section and `expected_outputs.json`.
