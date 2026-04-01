## SBOM X-Ray Lab — Student Guide

### 1. Background: CycloneDX, SPDX, and PURLs

**CycloneDX**  
- CycloneDX is a **standard format for SBOMs** (Software Bills of Materials).  
- It defines a schema (JSON/XML) for listing:
  - Components (libraries, frameworks, OS packages, containers, etc.)
  - Dependencies and relationships (who depends on what)
  - Metadata (supplier, hashes, licenses, provenance, cryptography, services)  
- You can think of it as a **strongly typed “ingredient list”** for software, designed with security and supply-chain use cases in mind.

**SPDX (Software Package Data Exchange)**  
- SPDX is another **SBOM standard**, originally focused on **license and compliance** information.  
- It now covers:
  - Packages, files, relationships
  - Licenses and copyright
  - Security metadata (with extensions)  
- SPDX = **Software Package Data Exchange**.  
- In this lab, you will briefly compare CycloneDX and SPDX to see that they both answer “what’s in here?” but with different object models.

**PURLs (Package URLs)**  
- A PURL is a **standardized way to name a software component**, including:
  - Ecosystem (e.g., `npm`, `pypi`, `maven`, `deb`, `rpm`)
  - Package name
  - Version
  - Optional qualifiers / subpaths  
- Example:  
  - `pkg:maven/org.apache.logging.log4j/log4j-core@2.14.1`  
  - `pkg:npm/left-pad@1.3.0`  
- PURLs let you **uniquely identify a dependency across systems and tools**, which is critical when you’re:
  - Matching components to vulnerabilities
  - Comparing SBOMs from different tools
  - Tracking shared dependencies across applications

---

### 2. Lab Overview

**Goal:** Learn to generate, read, and analyze SBOMs in an air-gapped environment.  
You will:
- Generate an SBOM from a container image using **Syft** (CycloneDX format).
- Compare it to a vendor-provided **SPDX** SBOM.
- Explore dependencies and shared components.
- Check your SBOM against a **“Minimum Elements”** checklist.
- Complete a **“metadata scavenger hunt”** that builds SBOM literacy.

You are playing the role of a **Software Assurance Engineer** in a defense software directorate.

---

### 3. Scenario Narrative

You’ve been assigned to review a new application called **Flight Path**, delivered as a container image by an external vendor.

The vendor provided:
- A PDF “bill of materials” (marketing-level)
- An **SPDX SBOM** in JSON format

Your directorate’s policy says:
- “Trust but verify. Generate your **own SBOM** from the delivered image.”
- “Compare the internal SBOM with the vendor’s, and check it against our SBOM quality checklist.”

Your mission:
1. Generate an **internal CycloneDX SBOM** for the `flight-path` image.
2. Compare structure and content against the **vendor SPDX SBOM**.
3. Identify **dependencies** and **shared components** with another app.
4. Evaluate whether the SBOMs meet basic **completeness and quality** expectations.

---

### 4. Lab Environment and Artifacts

**Offline / air-gapped assumptions**

- This lab is designed to run **without internet access**. You will **not** use `docker pull`, live vulnerability feeds, or online SBOM services.
- All files are **pre-staged** on the analysis VM. If a command fails, ask the facilitator—do not try to “fix it from the internet.”

**Where files live (canonical)**

- On the VM, your facilitator will place artifacts under **`~/labs/sbom-xray/`** (Blue Team / analysis role).
- In the training module **source repository**, the same bundle lives under **`training/scenarios/sbom-xray-lab/artifacts/`** so maintainers can version-check Docker sources, SPDX, and checklists together.

On your lab VM you will have:

- **Tools** (pre-installed; versions are **pinned** for the class—see facilitator notes):
  - `syft` – SBOM generator (**target:** `1.23.1` when using the reference lab image)
  - `jq` – JSON processor (**target:** `1.7` or distro equivalent)
  - Standard shell tools: `cat`, `less`, `sort`, `uniq`, `grep`, `comm`, etc.

- **Artifacts** (in `~/labs/sbom-xray/`):
  - `flight-path-v1.tar` – container image archive for Flight Path
  - `radar-control-v1.tar` – **required** second app for shared-PURL / blast-radius exercises (PRD §7.F)
  - `vendor_claim.spdx.json` – vendor’s SPDX SBOM for Flight Path (intentionally imperfect for training)
  - `SBOM_Minimum_Elements.md` – simplified minimum-elements checklist (offline copy)
  - This **student guide** (and possibly a separate worksheet)

Everything is local; **no internet access is required or assumed**.

If you obtained the lab from the demo repository, container images may be stored under `artifacts/` as **`flight-path-v1.tar.gz`** and **`radar-control-v1.tar.gz`**. Run **`install-module1-offline.sh`** once from the bundle root; it decompresses them into **`flight-path-v1.tar`** and **`radar-control-v1.tar`** in your lab directory for the steps below.

#### Docker workflow (DEMO-FULL monorepo)

If you are using the root **Docker Compose** stack, the **`sbom-xray-lab`** service bind-mounts this lab at **`/lab`** inside the container. **Syft** and **jq** are installed in the image at build time (not downloaded again at runtime).

- Shell: from the repo root, run **`make sbom-shell`** or `docker compose exec sbom-xray-lab bash`.
- Treat **`/lab`** the same way as **`~/labs/sbom-xray/`** in the steps below (e.g. `flight-path-v1.tar` should live under `/lab` once staged).
- Stage artifacts into `/lab` once:

  ```bash
  docker compose exec sbom-xray-lab bash -c 'SBOM_XRAY_CONTAINER=1 bash /lab/install-module1-offline.sh --lab-dir /lab'
  ```

- Quick check: **`make sbom-validate`** from the repo root (runs `validate-module1-offline.sh --lab-dir /lab`).

The lab container is on an isolated **`sbom-lab`** network (not the Splunk **scenario** network) and has **no HTTP port** published — it is **CLI only**.

---

### 5. Learning Objectives

By the end of the lab, you should be able to:

1. **Generate SBOMs offline**
   - Use `syft` to generate a CycloneDX SBOM from a local container image.
2. **Navigate SBOM structure**
   - Locate metadata (supplier, author, timestamp, etc.).
   - Locate components and dependencies.
3. **Understand formats**
   - Explain, at a high level, the difference between CycloneDX and SPDX.
4. **Trace dependencies**
   - Distinguish between direct and transitive dependencies.
   - Follow a specific library through the dependency tree.
5. **See shared risk**
   - Identify components shared between two different applications.
6. **Evaluate SBOM quality**
   - Apply a simple checklist (e.g. NTIA / CISA minimum elements) to decide whether a given SBOM is “good enough” for your org.

---

### 6. Part 1 — Generate an Internal SBOM

#### Step 1.1 – Inspect the lab directory

```bash
cd ~/labs/sbom-xray
ls
```

You should see:
- `flight-path-v1.tar`
- `radar-control-v1.tar`
- `vendor_claim.spdx.json`
- `SBOM_Minimum_Elements.md`

#### Step 1.2 – Run Syft in CycloneDX mode

Generate a CycloneDX JSON SBOM:

```bash
syft flight-path-v1.tar -o cyclonedx-json > internal_cdx.json
```

Check that the file was created:

```bash
ls internal_cdx.json
```

#### Step 1.3 – Peek at the metadata

Use `jq` to view just the metadata section:

```bash
jq '.metadata' internal_cdx.json | less
```

Also inspect **tooling** explicitly (Syft nests tools under `metadata.tools` in CycloneDX 1.6-style output):

```bash
jq '.metadata.tools' internal_cdx.json | less
```

Questions to answer (record your answers in your worksheet):
1. Who is listed as the **supplier** (if present)?
2. Is there a **timestamp** associated with the SBOM creation?
3. Do you see any indication of which **tool** created this SBOM?

---

### 7. Part 2 — Compare CycloneDX vs SPDX

Now you’ll compare your **CycloneDX** SBOM (internal) with the **SPDX** SBOM provided by the vendor.

#### Step 2.1 – Count components in both SBOMs

CycloneDX:

```bash
jq '.components | length' internal_cdx.json
```

Vendor SPDX:

```bash
jq '.packages | length' vendor_claim.spdx.json
```

Record:
- Number of components in CycloneDX (`internal_cdx.json`)
- Number of packages in SPDX (`vendor_claim.spdx.json`)

Are they the same? If not, consider why they might differ.

#### Step 2.2 – Compare supplier / creator

CycloneDX (supplier / metadata):

```bash
jq '.metadata.supplier // .metadata.supplier.name // .metadata.component.supplier' internal_cdx.json
```

SPDX (creation info):

```bash
jq '.creationInfo' vendor_claim.spdx.json | less
```

Questions:
1. Does the **supplier**/creator information match between the two SBOMs?
2. Does one have **more detail** than the other (e.g., email, tool version)?

---

### 8. Part 3 — Explore Dependencies

Here you’ll get a feel for how dependencies are represented in CycloneDX.

#### Step 3.1 – Locate dependencies in CycloneDX

```bash
jq '.dependencies' internal_cdx.json | less
```

CycloneDX dependencies often reference components by their **PURL or bom-ref**.

#### Step 3.2 – Focus on a single component (Python example)

These training images are **Python**-based. A good teaching pair is **`requests`** (popular HTTP client) and **`urllib3`** (a lower-level library that `requests` depends on).

Search for `urllib3` in the components list:

```bash
jq '.components[] | select(.name == "urllib3")' internal_cdx.json
```

Note:
- The component’s **name**.
- The **version**.
- The **purl**.

Now, see how **`requests`** depends on **`urllib3`** using the CycloneDX `dependencies` list (refs often include the PURL and/or a Syft `package-id` suffix):

```bash
jq '.dependencies[] | select(.ref | tostring | contains("requests"))' internal_cdx.json
```

If your output is hard to read, try filtering to the depends-on list only:

```bash
jq '.dependencies[] | select(.ref | tostring | contains("requests")) | {ref, dependsOn}' internal_cdx.json
```

Questions:
1. Is **`urllib3`** **direct** (installed as a top-level dependency of the container image) or **transitive** (pulled in because **`requests`** needs it)?
2. Which component **declares** that dependency edge in the SBOM (`dependencies[].ref` / `dependsOn`)?

---

### 9. Part 4 — Shared Components Across Applications

Your lab includes a **second** application (`radar-control`). You will repeat the process and look for **shared components** (PRD §7.F).

#### Step 4.1 – Generate SBOM for the second app

```bash
syft radar-control-v1.tar -o cyclonedx-json > radar_cdx.json
```

#### Step 4.2 – Extract PURLs for each app

```bash
jq -r '.components[].purl | select(. != null)' internal_cdx.json > flight-path-purls.txt
jq -r '.components[].purl | select(. != null)' radar_cdx.json > radar-purls.txt
```

Sort them:

```bash
sort flight-path-purls.txt > flight-path-purls.sorted.txt
sort radar-purls.txt > radar-purls.sorted.txt
```

Find the intersection (shared components):

```bash
comm -12 flight-path-purls.sorted.txt radar-purls.sorted.txt > shared-purls.txt
cat shared-purls.txt
```

Questions:
1. Which libraries are **shared** between the two applications?
2. If a vulnerability is found in one of these shared components later:
   - Which applications would be affected?
   - How might this change your **patch prioritization**?

---

### 10. Part 5 — Minimum Elements / Quality Check

Using `SBOM_Minimum_Elements.md` (offline checklist), evaluate **whether the SBOMs are “good enough”**.

Typical items to check:
- **Supplier / author** is clearly recorded.
- Each component has:
  - Name
  - Version
  - Unique identifier (PURL, CPE, or similar)
  - At least one hash (e.g., SHA-256) where appropriate.
- Relationships (e.g., `depends-on`) are present.
- SBOM includes a **timestamp** / version so you know when it was generated.

For both:
1. Internal CycloneDX SBOM
2. Vendor SPDX SBOM

Decide:
- Does each SBOM satisfy the **minimum elements**?
- Which SBOM would you trust more in an incident?
- What **specific improvements** would you ask the vendor to make?

---

### 11. Metadata Scavenger Hunt (Gamified Section)

Answer as many of these as you can (time-boxed if the instructor chooses):

1. What is the PURL of the **primary web framework** used by Flight Path?
2. How many total **`components`** are in the internal CycloneDX SBOM (`internal_cdx.json`)?
3. Name one **transitive** Python dependency and name the **direct** Python package that depends on it (hint: use `requests` / `urllib3`).
4. List **two** PURLs that appear in **both** applications (after intersection). (Either two Python packages **or** two OS packages is fine—be specific.)
5. Does the vendor SPDX SBOM include **package checksums** (`checksums` / hash objects)? If yes, paste an example SPDXID. If no, describe the risk in one sentence.
6. Compare **vendor** `creationInfo.created` vs **internal** `metadata.timestamp`. Which looks more “fresh,” and why does freshness matter?
7. Pick **one** shared Python dependency from your intersection list—if it had a CVE tomorrow, which **named lab apps** are in the blast radius?

The instructor may score answers for **correctness and completeness**.

---

### 11a. Critique memo (ISSO / ISSM style)

Write **2–3 sentences** suitable for a busy **ISSO/ISSM** briefing that:

- States whether you trust the **vendor SPDX** as a complete picture of the delivered container, **based on evidence** (counts, relationships, hashes, unknown markers).
- Names **one operational implication** (patch priority, monitoring scope, or procurement follow-up).

This satisfies PRD §7.H’s written summary requirement.

---

### 12. Reflection Questions

After completing the hands-on tasks, take a few minutes to reflect:

1. Before this lab, what did “SBOM” mean to you? Has that changed?
2. Did anything about the **size or complexity** of the SBOM surprise you?
3. If a vendor sent you a **low-quality SBOM**, would you be able to tell? What signals would you look for?
4. How might SBOMs fit into:
   - CI/CD / build pipelines
   - Incident response
   - Acquisition/procurement reviews

Be prepared to share one insight in the debrief.

---

### 13. Summary

In this SBOM X-Ray Lab, you:
- Generated a CycloneDX SBOM offline using Syft.
- Explored and compared CycloneDX and SPDX structures.
- Traced dependencies, including transitive dependencies.
- Identified shared components across two applications.
- Evaluated SBOM quality against a minimum-elements checklist.

These skills are the **foundation** for later labs that involve:
- Mapping vulnerabilities and advisories to SBOMs (incident response).
- Enforcing policy and license constraints (governance).
- Evaluating vendors and long-term lifecycle risk (procurement, EOL).

**Module 2+ preview (not in scope today):** you will reuse **PURLs** and **shared dependency** intuition when mapping CVEs, diffing releases, and attaching policy—but this module stays strictly **offline generation, navigation, comparison, and critique**.

You now have the baseline literacy to treat SBOMs as **operational tools**, not just buzzwords.

