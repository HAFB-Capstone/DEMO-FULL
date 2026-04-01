# SBOM X-Ray Lab (Module 1) - Student Worksheet

Use this worksheet after your lab VM is already up and running.

## 1) Scenario: Your Mission

You are a Software Assurance Engineer supporting a defense software team.

A vendor delivered the **Flight Path** application as a container image and provided a vendor SBOM.
Your team policy is: **trust but verify**.

You must:

1. Generate your own internal SBOM from the delivered image.
2. Compare your internal SBOM to the vendor SPDX SBOM.
3. Trace dependency relationships (direct and transitive).
4. Find components shared with a second application.
5. Judge SBOM quality against minimum elements.

## 2) SBOM Basics You Need First

- **SBOM**: A software ingredient list for a deployable unit (image/app), including packages, versions, and relationships.
- **CycloneDX**: SBOM format focused on security and operational use (components + dependencies + metadata).
- **SPDX**: SBOM format that is widely used for licensing/compliance and can also capture package metadata.
- **PURL**: Package URL used to uniquely identify a component, for example `pkg:pypi/requests@2.31.0`.
- **Direct dependency**: You intentionally install it (example: `requests` in a Dockerfile).
- **Transitive dependency**: Pulled in because a direct dependency needs it (example: `urllib3` via `requests`).

## 3) Lab Structure (What You Will Do)

Part A. Generate internal CycloneDX SBOM for Flight Path.  
Part B. Compare internal CycloneDX vs vendor SPDX.  
Part C. Trace dependency edges in CycloneDX.  
Part D. Build second SBOM and find shared PURLs.  
Part E. Score both SBOMs against minimum elements.

## 4) Pre-Flight Check

Run these commands first:

```bash
cd ~/labs/sbom-xray
ls
which syft
which jq
```

What each command does:

- `cd ~/labs/sbom-xray`: moves into the lab folder.
- `ls`: lists files in the current directory.
- `which syft`: confirms Syft is installed and on `PATH`.
- `which jq`: confirms jq is installed and on `PATH`.

Expected files:

- `flight-path-v1.tar`
- `radar-control-v1.tar`
- `vendor_claim.spdx.json`
- `SBOM_Minimum_Elements.md`

## 5) Part A - Generate Internal SBOM

### Command 1: Generate CycloneDX SBOM

```bash
syft flight-path-v1.tar -o cyclonedx-json > internal_cdx.json
```

Command breakdown:

- `syft flight-path-v1.tar`: scans the local image archive.
- `-o cyclonedx-json`: outputs SBOM in CycloneDX JSON format.
- `> internal_cdx.json`: saves output to a file.

### Command 2: Confirm output file exists

```bash
ls internal_cdx.json
```

### Command 3: Inspect top-level metadata

```bash
jq '.metadata' internal_cdx.json | less
```

Command breakdown:

- `jq '.metadata' ...`: extracts only the metadata object.
- `| less`: opens paged view so large JSON is readable.

Note: To exit `less`, press `q`.

### Command 4: Inspect tool metadata

```bash
jq '.metadata.tools' internal_cdx.json | less
```

Worksheet questions:

1. What timestamp is shown for SBOM creation?
2. Which tool and version generated the SBOM?
3. Is a supplier field present, missing, or null?

## 6) Part B - Compare CycloneDX to Vendor SPDX

### Command 1: Count CycloneDX components

```bash
jq '.components | length' internal_cdx.json
```

### Command 2: Count vendor SPDX packages

```bash
jq '.packages | length' vendor_claim.spdx.json
```

### Command 3: Inspect vendor creation info

```bash
jq '.creationInfo' vendor_claim.spdx.json | less
```

### Command 4: Look for explicit unknown markers

```bash
jq '.. | strings | select(. == "NOASSERTION")' vendor_claim.spdx.json
```

Worksheet questions:

1. Why is the vendor package count far smaller than internal component count?
2. What does `NOASSERTION` mean in practice?
3. Which SBOM appears fresher, and why does freshness matter for incident response?

## 7) Part C - Dependency Reasoning

### Command 1: View dependency graph section

```bash
jq '.dependencies' internal_cdx.json | less
```

### Command 2: Find urllib3 component entry

```bash
jq '.components[] | select(.name == "urllib3")' internal_cdx.json
```

### Command 3: Find dependency edges for requests

```bash
jq '.dependencies[] | select(.ref | tostring | contains("requests")) | {ref, dependsOn}' internal_cdx.json
```

Before answering the questions, use these definitions:

- **Direct dependency**: A package intentionally installed by the image author (for this lab, packages installed in the Dockerfile such as `requests`).
- **Transitive dependency**: A package not installed directly, but pulled in because a direct dependency requires it (for this lab, `urllib3` is usually pulled in by `requests`).
- **Dependency edge**: A relationship link in the SBOM graph that says "component A depends on component B."  
  In CycloneDX, this appears as one object in `.dependencies` where:
  - `ref` = the parent component (the thing that depends on others), and
  - `dependsOn` = list of child components it needs.

Why this matters operationally:

- If you only know package names, you know "what exists."
- If you also know dependency edges, you know "what breaks if this package is vulnerable."
- That lets you prioritize patches based on impact and blast radius, not just CVE severity.

Worksheet questions:

1. Is `urllib3` direct or transitive in this image?
2. Which `ref` declares the dependency edge?
3. Why does dependency-edge visibility help patch prioritization?

## 8) Part D - Shared Components Across Two Applications

### Command 1: Generate SBOM for second image

```bash
syft radar-control-v1.tar -o cyclonedx-json > radar_cdx.json
```

### Command 2: Extract non-null PURLs from each SBOM

```bash
jq -r '.components[].purl | select(. != null)' internal_cdx.json > flight-path-purls.txt
jq -r '.components[].purl | select(. != null)' radar_cdx.json > radar-purls.txt
```

### Command 3: Sort each PURL list

```bash
sort flight-path-purls.txt > flight-path-purls.sorted.txt
sort radar-purls.txt > radar-purls.sorted.txt
```

### Command 4: Intersect sorted lists

```bash
comm -12 flight-path-purls.sorted.txt radar-purls.sorted.txt > shared-purls.txt
cat shared-purls.txt
```

Command breakdown:

- `comm -12`: prints only lines that exist in both sorted files.
- `shared-purls.txt`: saved list of shared components.

Worksheet questions:

1. List at least 2 shared PURLs.
2. If one shared library gets a CVE tomorrow, which applications are in blast radius?
3. How should that change response priority?

## 9) Part E - Minimum Elements Quality Check

Open checklist:

```bash
less SBOM_Minimum_Elements.md
```

Use the checklist to evaluate both:

- `internal_cdx.json`
- `vendor_claim.spdx.json`

Worksheet prompts:

1. Which minimum elements are clearly present in internal CycloneDX?
2. Which elements are weak or missing in vendor SPDX?
3. What single improvement should be required from the vendor before acceptance?

## 10) Short Critique Memo (2-3 sentences)

Write a short memo for an ISSO/ISSM audience:

- State whether you trust the vendor SBOM as a complete picture.
- Cite evidence (counts, relationships, hashes, unknown markers).
- Name one operational impact (patching, monitoring, or vendor follow-up).

## 11) Final Submission Checklist

- `internal_cdx.json` created
- `radar_cdx.json` created
- `shared-purls.txt` created
- All worksheet questions answered
- Critique memo written

## 12) Answer Key (Student Self-Check)

Use this to confirm your work. Some values (like timestamp) are run-dependent.

### Part A expected answers

1. **Timestamp shown for SBOM creation**  
   - Any valid ISO UTC timestamp from your `internal_cdx.json` metadata is correct (example: `2026-03-25T05:32:19Z`).
2. **Tool and version**  
   - Expected: `syft` `1.23.1` (pinned).
3. **Supplier field**  
   - Expected in this lab: typically missing/absent in internal CycloneDX metadata.

### Part B expected answers

1. **Why vendor package count is much smaller**  
   - Vendor SPDX in this lab is intentionally a thin claim; internal CycloneDX enumerates far more OS + language components.
2. **Meaning of `NOASSERTION`**  
   - Explicit "known unknown" marker in SPDX; the producer is not asserting a value.
3. **Which SBOM is fresher**  
   - Usually internal CycloneDX (generated now) vs vendor file timestamp (older static claim).

### Part C expected answers

1. **Is `urllib3` direct or transitive?**  
   - Usually transitive via `requests`.
2. **Which `ref` declares the edge?**  
   - The `ref` for `requests` (or its bom-ref/purl-like identifier) with `dependsOn` containing `urllib3`.
3. **Why edges help patch prioritization**  
   - They show impact paths and blast radius, so teams can fix vulnerabilities that affect more critical dependency chains first.

### Part D expected answers

1. **At least two shared PURLs**  
   - Must include:
     - `pkg:pypi/requests@2.31.0`
     - `pkg:pypi/urllib3@2.6.3`
2. **Blast radius if a shared dependency gets a CVE**  
   - Both Flight Path and Radar Control are affected.
3. **Response priority implication**  
   - Shared dependencies generally deserve higher patch priority due to cross-application impact.

### Part E expected answers

Strong answers identify concrete evidence, such as:

- Internal CycloneDX contains rich inventory, tool metadata, timestamp, and dependency relationships.
- Vendor SPDX has notable gaps (small package set, many `NOASSERTION` fields, limited relationship detail, no package checksums).
- A valid improvement request: fuller package inventory, checksums, and richer dependency relationships.

### Critique memo self-check

A strong 2-3 sentence memo should:

- Make a trust judgment on vendor SBOM completeness.
- Cite evidence (counts, unknowns, relationships, checksums).
- State one operational consequence (patching priority, monitoring scope, or vendor follow-up requirement).

