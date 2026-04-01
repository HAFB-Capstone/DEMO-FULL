# SBOM X-Ray Lab (Module 1) - Answer Key

This key is for facilitators and student self-check.
Use it with:

- `sbom-xray-lab-student-worksheet.md`
- `sbom-xray-lab-student-guide.md`
- `training/scenarios/sbom-xray-lab/expected_outputs.json`

## Important grading note

Some values are deterministic (for pinned artifacts), while others vary by run time.

- **Run-dependent:** `metadata.timestamp` in internal CycloneDX.
- **Pinned/expected:** Syft version (`1.23.1`), vendor SPDX package count (`9`), example shared PURLs.

## Part A - Generate Internal SBOM

### Q: What timestamp is shown for SBOM creation?
- Expected pattern: ISO-8601 UTC timestamp from `internal_cdx.json` metadata.
- Example: `2026-03-25T05:32:19Z`.
- Grading: any valid recent scan timestamp is correct.

### Q: Which tool and version generated the SBOM?
- Expected: `syft` and version `1.23.1` (pinned).
- If a different version appears, results may differ from reference counts.

### Q: Is a supplier field present, missing, or null?
- Expected for this training image: supplier is usually **absent/missing** in internal CycloneDX metadata.
- Accept `null` only if student demonstrates the queried path returns null in their output.

## Part B - Compare CycloneDX vs Vendor SPDX

### Q: CycloneDX component count (`internal_cdx.json`)?
- Expected range: `3000-4000` components.
- Representative reference value: about `3362` with pinned toolchain.

### Q: Vendor SPDX package count?
- Expected exact value: `9`.

### Q: Why do counts differ?
- Expected concept: vendor SPDX is intentionally a thin claim subset; internal Syft SBOM enumerates many OS + Python components.

### Q: What does `NOASSERTION` mean?
- Expected concept: explicit known-unknown marker in SPDX (not a confirmed value).

### Q: Which SBOM is fresher?
- Expected concept: internal CycloneDX is generated at scan time and is usually fresher than vendor timestamp (`2024-06-01T12:00:00Z` in staged SPDX).

## Part C - Dependency Reasoning

### Q: Is `urllib3` direct or transitive?
- Expected: typically **transitive** via `requests`.

### Q: Which ref declares the edge?
- Expected concept: a `dependencies[].ref` corresponding to `requests` with `dependsOn` including a ref for `urllib3`.

### Q: Why do dependency edges matter?
- Expected concept: supports blast-radius and patch-priority decisions.

## Part D - Shared Components Across Two Apps

### Q: At least two shared PURLs?
- Must include (expected set):
  - `pkg:pypi/requests@2.31.0`
  - `pkg:pypi/urllib3@2.6.3`

### Q: Blast radius if shared component gets a CVE?
- Expected: both Flight Path and Radar Control affected.

## Part E - Minimum Elements / Quality Check

### Strong internal CycloneDX evidence should include:
- Tool metadata and timestamp.
- Large component inventory with names/versions/PURLs.
- Dependency relationships present.

### Vendor SPDX deficiencies students should identify (any 3+):
- Very small package set (`9`) compared with internal inventory scale.
- Missing package checksums.
- Thin relationships (few edges, weak transitive visibility).
- Repeated `NOASSERTION` fields (`supplier`, `downloadLocation`, `license*`, etc.).

### One required vendor improvement (examples)
- Provide complete package inventory for the delivered image.
- Include package checksums and richer dependency relationships.
- Replace `NOASSERTION` where practical with real values.

## Critique Memo (2-3 sentence) exemplar

The vendor SPDX is not a complete operational picture of the delivered container because it lists only 9 packages and provides limited relationships compared to the internal CycloneDX SBOM that enumerates thousands of components. The vendor file also uses `NOASSERTION` broadly and lacks package checksums, reducing confidence for automation and incident response. We should require a fuller SBOM with checksums and richer dependency edges before acceptance.
