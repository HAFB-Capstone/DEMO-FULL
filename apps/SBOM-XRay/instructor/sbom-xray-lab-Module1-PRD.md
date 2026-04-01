# SBOM X-Ray Lab (Module 1) — PRD

## 1. Summary
Create a **foundational SBOM literacy training module** (“SBOM X‑Ray Lab”) for the HAFB cyber training lab that runs **entirely offline (air‑gapped)** and teaches students to **generate, read, compare, and critique** SBOMs using simple local tooling.

## 2. Problem / Opportunity
- **Problem**: Teams are increasingly required to use SBOMs for supply-chain risk, incident response, and acquisition, but many engineers/analysts lack “hands-on muscle memory” for working with real SBOM artifacts (large JSON, multiple standards, dependency relationships, and quality gaps), especially in **air-gapped** environments where typical SaaS and live feeds don’t exist.
- **Opportunity**: A short, repeatable, CLI-first lab can establish baseline competence that later modules (vulnerability mapping, forensic diffing, governance/policy, provenance) can build upon.

## 3. Users and Stakeholders
- **Primary users**:
  - HAFB / 309th SWEG developers learning supply-chain defense fundamentals.
  - Cyber analysts (Blue team) who must interpret SBOMs during assessments and incidents.
- **Secondary users**:
  - Information System Security Officers (ISSOs) / Information System Security Managers (ISSMs) who consume SBOM-derived summaries in risk briefings.
  - Instructors/facilitators who run the lab and score outcomes.
  - Maintainers/agents who update artifacts and keep the lab working as tool versions change.
- **Stakeholders**:
  - HAFB project leadership and capstone maintainers responsible for repeatable delivery.

## 4. Scope
### In scope
- **Offline SBOM generation** from a local artifact (container image archive `.tar`) into **CycloneDX JSON** (initial “internal truth” SBOM).
- **SBOM navigation literacy**:
  - Locate and interpret metadata (e.g., supplier/creator, timestamp, tool info).
  - Locate components/packages and key identifiers (e.g., name, version, PURL).
  - Locate and reason about dependency relationships (direct vs transitive).
- **Format comparison**:
  - Compare **CycloneDX** (internally generated) vs **SPDX** (vendor-provided) for the same delivered application.
  - Simple comparisons such as component counts and metadata differences.
- **Cross-application shared dependency analysis**:
  - Generate SBOMs for two apps and compute intersection using PURLs (shared risk/blast radius).
- **SBOM quality evaluation**:
  - Apply a simple “minimum elements” checklist (e.g., CISA/NTIA-aligned) to critique completeness and trustworthiness.
  - Distinguish between **missing data** and **explicit “known unknowns”** (e.g., `NOASSERTION` in SPDX) and explain their risk implications.
- **Student-facing materials**:
  - A clear student guide with a narrative scenario and step-by-step tasks (already drafted; PRD governs the “what/why”).
  - A lightweight scavenger-hunt style assessment (metadata/structure questions with verifiable answers).
- **Instructor-facing needs** (minimum set):
  - Timing guidance and a rubric for scoring/validation (answer key can be a later deliverable, but must be planned for).

### Out of scope (for this PRD / Module 1)
- Live vulnerability scanning with external feeds, internet APIs, or SaaS tooling.
- Dependency update/remediation workflows (patching, rebuilding images, CI/CD integration).
- Complex UI dashboards, databases, or web services for SBOM analysis.
- Cryptographic/provenance attestation validation (SLSA/cosign), VEX workflows, EOL scanning (these may belong in later modules).
- Replicating HAFB classified platforms; this training uses open-source analogues and sandbox artifacts.

## 5. Constraints
- **Air-gapped/offline-first**:
  - No internet access; no reliance on external APIs, remote registries, or online documentation at runtime.
  - All artifacts must be pre-staged on the training VM(s).
- **Tooling constraints**:
  - Must be runnable with a minimal CLI toolset such as: `syft`, `jq`, and standard shell utilities (`sort`, `comm`, `less`).
  - Commands documented must be readable and teachable (avoid overly complex one-liners).
  - Training images should pin **tool versions** (e.g., specific Syft and `jq` releases) so documented JSON paths and examples remain valid across cohorts.
- **Operational constraints**:
  - Artifacts must be safe for training (no secrets, no proprietary code).
  - Lab must be repeatable across cohorts (stable paths, deterministic inputs, clear setup).
- **Platform constraints**:
  - Designed to run on the lab’s analysis environment (commonly “Blue Team VM” or equivalent), consistent with the larger Proxmox-based lab model.

## 6. Risks and Tradeoffs
- **Student overwhelm from SBOM size/complexity**:
  - Mitigation: scaffolded tasks, focused queries, and a limited set of “must-find” fields.
- **Tool/version drift** (Syft output shapes, CycloneDX/SPDX revisions):
  - Mitigation: pin known-good tool versions in the training image build process, and validate documented JSON paths periodically.
- **Artifact realism vs safety**:
  - Tradeoff: images must be realistic enough to demonstrate dependency graphs and common libraries, but sanitized to avoid sensitive content.
- **Vendor SBOM credibility**:
  - Tradeoff: “vendor_claim.spdx.json” should be structurally valid yet intentionally imperfect; too perfect undermines the lesson, too broken becomes a debugging exercise.
  - Intentional imperfections should focus on **2025 CISA minimum elements gaps** (e.g., missing hashes, incomplete dependency relationships, absent generation context) and realistic naming/license inconsistencies rather than structural JSON errors.
- **Over-scoping into later modules**:
  - Mitigation: keep Module 1 strictly about SBOM literacy and critique; push vuln/provenance/policy into subsequent PRDs.

## 7. Acceptance Criteria
- **A. Offline execution**
  - [ ] A student can complete the lab **without internet access**, using only local files and tools.
  - [ ] The student guide explicitly states offline assumptions and where artifacts live.
- **B. SBOM generation**
  - [ ] Students can generate a CycloneDX JSON SBOM from a provided container `.tar` artifact and verify output file creation.
- **C. Navigation + interpretation**
  - [ ] Students can extract and explain at least: tool metadata, timestamp (or note absence), and at least one supplier/creator field (or note absence) from the generated SBOM.
  - [ ] Students can locate a specific component, report its name/version, and identify a unique identifier (preferably PURL) if present.
- **D. Format comparison**
  - [ ] Students can compare internal CycloneDX vs vendor SPDX: component/package counts and at least one metadata difference, and can describe why discrepancies might exist.
- **E. Dependency reasoning**
  - [ ] Students can distinguish direct vs transitive dependency for at least one named library using SBOM relationship data (or a guided approximation if relationship fidelity varies).
- **F. Shared dependency / blast radius**
  - [ ] With two applications, students can produce a list of shared components (PURLs) and articulate the operational implication (“one vuln can impact multiple apps”).
- **G. Quality critique**
  - [ ] Students can apply a minimum-elements checklist and produce a short critique of each SBOM (what’s present, what’s missing, what to request from a vendor).
  - [ ] For the vendor SPDX SBOM, students can identify and document at least **three specific deficiencies** aligned to modern minimum-elements expectations (e.g., missing component hashes for non-trivial components, absent or vague generation context, missing or inconsistent tool identification, incomplete dependency relationships).
  - [ ] Students can point to at least one instance of an explicit “known unknown” marker (e.g., `NOASSERTION` or equivalent) and explain, in plain language, the difference between “no data provided” and “data explicitly unknown.”
- **H. Assessment**
  - [ ] A scavenger-hunt question set exists with objectively checkable answers based on provided artifacts.
  - [ ] The lab requires a brief written “critique memo” or 2–3 sentence risk summary suitable for an ISSO/ISSM, based on the student’s SBOM comparison findings.

## 8. Dependencies and References
- **Execution (plan + roadmap)**:
  - `docs/sbom-xray-lab-Module1-plan.md` — architecture, sequencing, validation approach
  - `ai/roadmaps/2026-03-20_sbom-xray-lab-Module1_roadmap.md` — phased checklist (see `ai/roadmaps/README.md`; `ai/` is gitignored in this repo)
- **Related docs in this repo**:
  - `PROJECT-CONTEXT.md` (HAFB project mission and stakeholders)
  - `JARVIS-ACCOUNTABILITY.md` (process + canonical doc locations)
  - `Air-Gapped SBOM Training Module Design.md` (broader curriculum design draft)
  - `sbom-xray-lab-agent-brief.md` (implementation/facilitation brief)
  - `sbom-xray-lab-student-guide.md` (student-facing lab flow)
- **Artifact dependencies (must be provided to students offline)**:
  - Container image tar(s): e.g., `flight-path-v1.tar` and a second app (e.g., `radar-control-v1.tar`)
  - Vendor SBOM: `vendor_claim.spdx.json`
  - Minimum-elements checklist: PDF or simplified Markdown (local copy)
- **Tool dependencies**:
  - `syft` and `jq` (plus basic shell utilities)

