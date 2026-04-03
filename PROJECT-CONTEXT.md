# HAFB Project Context — Universal Source of Truth

**Use:** Give this document to any new agent (including JARVIS) or teammate to get caught up on the purpose, scope, and structure of the HAFB project. It is the **knowledge and context** source of truth. For **process** (pipeline, Git, roadmaps), use the JARVIS Agent Brief (`JARVIS-ACCOUNTABILITY.md`) in repos that include it.

**Scope:** Sections **1–9** describe the overall Capstone program and GitHub organization. **Sections 10–11** are specific to **this repository** (`DEMO-FULL`). When you copy this file into another repo, replace Section 11 (and adjust Section 10) so agents know where they are.

---

## 1. Project Purpose and Mission

### What this project is

- A **cyber training lab** and capstone effort for **Hill Air Force Base (HAFB)**, in partnership with the **309th Software Engineering Group (309th SWEG)**.
- The lab provides **skill-based security training** using **open-source analogues** — the environment does **not** replicate HAFB's classified systems (e.g. Red Hat, OpenShift, Harvester, Talos). The goal is to teach defensive skills, especially against **supply-chain attacks**, in a safe, isolated "sandbox."
- **Target audience:** Directorate-wide **developers** who currently lack access to isolated environments for security testing. The platform is intended as a **training tool** for them.
- **Outcome:** A working, repeatable training environment where Red Team, Blue Team, and "Victim" systems work together so developers can practice attack and defense in a realistic but controlled setting.

### Why it exists

- **Supply-chain risk** is critical for the 309th SWEG: they manage mission-critical software (e.g. aircraft systems, radar, flight software, avionics). A compromised dependency can affect many systems; **SBOM** and supply-chain defense are core to their posture.
- The project delivers **training infrastructure** (VMs, vulnerable apps, Red/Blue tooling) and **scenarios** so developers learn to detect, respond to, and mitigate threats — including those stemming from dependencies and supply chain.

### What "success" looks like

- Deployable **Red**, **Blue**, and **Victim** environments (Linux and, where applicable, Windows).
- **Vulnerable applications** (e.g. web apps with SQLi, XSS, weak auth) and, where relevant, **specialized simulators** (e.g. MIL-STD-1553) for mission-relevant training.
- **Training scenarios** (e.g. supply-chain poisoning, credential theft, RCE) with student and instructor materials, aligned to MITRE ATT&CK where appropriate.
- **SBOM** and vulnerability scanning integrated into the workflow so trainees see how dependency and supply-chain risks are identified and managed.

---

## 2. Stakeholders and Roles

| Role / Entity | Description |
|--------------|-------------|
| **309th SWEG** | Customer / partner at Hill Air Force Base. Manages mission-critical software; cares deeply about supply-chain security and SBOM. |
| **Garrett Kuns** | Primary technical lead for the project. |
| **Ski Camp** | External federal contract team; potential collaboration (own secure network/firewall). |
| **Capstone team** | Developers and contributors (e.g. Payton Womack, Cameron Hammond, Noah Haskett, Seth Brock, Taylor Preslar, Charlotte Griffin). Roles include Infrastructure Lead, Red-Team Lead, Blue Team/Telemetry Engineers, App/Target Developer, Project Manager. |
| **HAFB** | Provides funding and hardware for the project; timeline and specifics may be in flux. |

---

## 3. Repository Map (GitHub Organization)

The project is spread across **nine repositories**. This is the canonical map.

| # | Repository | Purpose | Role in project |
|---|------------|---------|------------------|
| 1 | **RT-template** | **Starter template for Red Team tools.** Used to create tools or services that assist the Red Team during penetration testing or adversarial simulations (e.g. scanners, exploit frameworks, reconnaissance). | Ensures all Red Team tools share a consistent, reusable starting point. |
| 2 | **VULN-template** | **Starter template for vulnerable applications.** Used to build apps that simulate vulnerabilities (SQL injection, weak auth, XSS, etc.) for testing and learning. Uses Docker for isolation. | Ensures all vulnerable apps have a consistent framework and can plug into the Victim/infra setup. |
| 3 | **srv** | **Server-side resources for Debian machines.** Scripts, configs, and applications for the server directory on a Debian host. Deployed in a **Proxmox** hypervisor-based virtualized environment. | Supports infrastructure and backend operations (services, scripts) for the lab. |
| 4 | **BT-template** | **Starter template for Blue Team tools.** Used to develop defensive tools, monitoring, or services (e.g. intrusion detection, log analysis). | Ensures all Blue Team tools share a consistent, reusable starting point. |
| 5 | **VULN-infra-linux** | **Vulnerable infrastructure for Linux.** Manages Docker networks, reverse proxies (e.g. NGINX), and deployment of vulnerable **Linux** services (e.g. apps built from VULN-template). | Provides the Linux-based attack surface for pen testing and training. |
| 6 | **VULN-infra-windows** | **Vulnerable infrastructure for Windows.** Manages Docker networks, reverse proxy (e.g. IIS with ARR), and deployment of vulnerable **Windows** services. | Provides a Windows-based, enterprise-like attack surface for pen testing and training. |
| 7 | **VULN-MIL-STD-1553** | **MIL-STD-1553 simulator (vulnerable application).** A Python-based web application that simulates MIL-STD-1553 (DoD standard for serial data buses in military/aerospace). Built from VULN-template; deployed via VULN-infra-linux. Includes intentional vulnerabilities for training on securing avionics communication systems. | Provides mission-relevant training on securing 1553-style systems; serves as an example of a specialized vulnerable app for a dedicated learning module. |
| 8 | **HAFB-Capstone-Project** | **Central / orchestrating repository.** High-level codebase, docs, training structure, and integration of deliverables from other repos. Main entry point for stakeholders. | Ties everything together; contains docs, architecture, training scenarios, and references to other repos. |
| 9 | **.github-private** | **Organization-level GitHub config.** Issue templates, PR templates, shared CI/CD workflows. | Standardizes collaboration and automation across all repos. |

---

## 4. How the Repositories Work Together

```
                    ┌─────────────────────────────────────┐
                    │     HAFB-Capstone-Project           │  ← Central repo: docs, training, orchestration
                    │     (overarching entry point)        │     (Proxmox / Ansible lab in full deployment)
                    └─────────────────┬───────────────────┘
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         │                            │                            │
         ▼                            ▼                            ▼
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│   Red Team      │          │   Blue Team     │          │    Victim       │
│                 │          │                 │          │                 │
│ RT-template     │          │ BT-template     │          │ VULN-template    │
│ (create tools)  │          │ (create tools) │          │ (create apps)   │
└────────┬────────┘          └────────┬────────┘          └────────┬────────┘
         │                             │                            │
         │                             │                            │
         ▼                             ▼                            ▼
   Tools used on                  Tools used on              Apps deployed via
   Red Team VM                    Blue Team VM               VULN-infra-linux
   (offensive)                    (defensive)                VULN-infra-windows
                                                                   │
                                                                   ▼
                                                          VULN-MIL-STD-1553
                                                          (example specialized app)

   srv → Server resources (Debian / Proxmox)
   .github-private → CI/CD, issues, PRs (all repos)
```

- **Red Team** uses **RT-template** to build offensive tools; those tools run in the Red Team environment and target Victim systems.
- **Blue Team** uses **BT-template** to build defensive/monitoring tools; those run in the Blue Team environment to detect and respond to Red Team activity.
- **Victim** uses **VULN-template** to build vulnerable apps; those apps are deployed via **VULN-infra-linux** and/or **VULN-infra-windows**. **VULN-MIL-STD-1553** is an example of a specialized vulnerable app built from VULN-template and deployed via VULN-infra-linux; it serves as a dedicated repository for a mission-relevant training module.
- **srv** holds server-side assets for Debian/Proxmox that support the overall infrastructure.
- **HAFB-Capstone-Project** is the central place for documentation, training scenarios, architecture, and "how it all fits together."
- **.github-private** applies org-wide automation and standards to every repo.

---

## 5. Key Concepts and Glossary

| Term | Definition |
|------|------------|
| **SBOM (Software Bill of Materials)** | An "ingredient list" for software: every library, plugin, and dependency. If a dependency is compromised (e.g. an NPM package), the SBOM lets HAFB quickly see which systems (e.g. flight software) are at risk. |
| **Supply-chain attack** | An attack that targets a system by compromising third-party tools or libraries it uses. Malicious code in a widely used package can affect many downstream users without attacking them directly. |
| **NPM (Node Package Manager)** | Default package manager for Node.js; large registry of shared code. Often targeted by typosquatting or malicious packages — relevant to HAFB's supply-chain concerns. |
| **Red Team** | Emulates real-world attackers. Uses RT-template to build offensive tools (scans, exploits, recon). |
| **Blue Team** | Defends, detects intrusions, mitigates. Uses BT-template to build defensive tools (IDS, log analysis, etc.). |
| **Victim** | The systems and apps that are intentionally vulnerable for training. Built with VULN-template; deployed via VULN-infra-*. |
| **DVWA** | Damn Vulnerable Web Application — a well-known intentionally insecure web app (e.g. SQLi, XSS). Sometimes referenced in training. |
| **Harvester** | Open-source hyperconverged infrastructure (HCI) on Kubernetes. Used at HAFB; the lab uses open-source analogues, not Harvester itself. |
| **Talos** | Linux distro for Kubernetes; immutable and ephemeral. Used at HAFB; lab does not replicate it. |
| **OpenShift** | Red Hat's enterprise Kubernetes platform. Used at HAFB in production; lab uses open-source analogues for training. |
| **MITRE ATT&CK** | Framework for classifying attack techniques. Training scenarios are mapped to ATT&CK where appropriate. |
| **Proxmox** | Hypervisor used for virtualized lab infrastructure (VMs) in the full Capstone deployment. The lab’s Proxmox host may run Red, Blue, Victim, and Ansible controller VMs; see `aiDocs/proxmox-overview.md` in **HAFB-Capstone-Project** for that layout. |
| **Ansible (full lab)** | In the Proxmox-based deployment, configuration and deployment are often driven from an **Ansible controller VM**. **This repository (DEMO-FULL)** does not use that path; it runs a **Docker Compose** stack from the repo root for local demos (see Section 11). |

---

## 6. Training and Scenarios (High Level)

- Training is **scenario-based** and can be mapped to **MITRE ATT&CK** (Initial Access, Execution, Persistence, Credential Access, etc.).
- Example scenario themes: **supply-chain poisoning**, **credential theft**, **RCE (remote code execution)**.
- Each scenario typically has: README, setup script, student guide, instructor solution, and ATT&CK mapping.
- **Vulnerable apps** (from VULN-template) and **VULN-infra-*** provide the attack surface; **Red** attacks, **Blue** defends and detects.

**DEMO-FULL (this repo)** bundles runnable slices of that story in one place: **SBOM** practice (**SBOM-XRay**), **Log4Shell (CVE-2021-44228)** services (**Log4j-Vulnerable**), a **MIL-STD-1553** multi-zone scenario (**MIL-STD-1553-Vulnerable**), and **Splunk**-oriented Blue-team monitoring assets (**apps/splunk**), all orchestrated by root **`docker-compose.yaml`** and **`Makefile`**.

---

## 7. Compliance and Security Context

- **NIST 800-53** and **CMMC** are relevant to HAFB's world; the project may reference controls (e.g. SA-15, SA-10, SR-3, SR-4, SR-5) in documentation.
- **SBOM** (e.g. Syft, Grype) is used to generate and scan bills of materials and vulnerabilities for training and awareness.
- The lab is for **training only**; vulnerable components and simulated attacks must stay in isolated, controlled environments.

---

## 8. Final Deliverables

At the conclusion of the development cycle, the project provides a **"DevOps-in-a-box"** package for Hill AFB:

| Deliverable | Description |
|-------------|-------------|
| **VZDump Backups** | Portable VM images (Red, Blue, Victim) ready for instant deployment on HAFB hardware. |
| **Instructor Runbook** | Step-by-step guides for environment setup, scenario execution, and student evaluation. |
| **Code Repository** | A complete Git history of all IaC templates (Packer, Ansible, Terraform) and playbooks. |
| **Training Scenarios** | Complete scenarios with student guides, instructor solutions, and MITRE ATT&CK mappings. |
| **Compliance Mapping** | Documentation aligning lab activities with NIST 800-53 and CMMC requirements. |

These deliverables ensure that HAFB can deploy, operate, and maintain the training lab independently.

---

## 9. Process and Agent Discipline

- **Project knowledge** (what you're reading): this document.
- **Process and accountability**: Repos in the org that include the **JARVIS Agent Brief** (`JARVIS-ACCOUNTABILITY.md`) define pipeline (PRD/Scope → Research → Plan → Roadmap → Execute), where docs live, and Git discipline. **This repo (DEMO-FULL)** may not include that file; use **`README.md`**, **`Makefile`**, and per-app READMEs under **`apps/`** for day-to-day workflow.

When you are in a repo, follow that repo's process docs for **how** to work; use this document for **what** the project is and **where** the repo fits.

---

## 10. Where to Find More (This Repo — DEMO-FULL)

- **Entry point:** [`README.md`](README.md) — prerequisites, `make setup` / `make up`, architecture (Mermaid), attack routes, demo walkthrough, port table, and Make targets.
- **Orchestration:** Root [`docker-compose.yaml`](docker-compose.yaml) — services, networks, and published ports for Splunk, Log4j lab, MIL-STD-1553 lab, SBOM-XRay container, and optional Universal Forwarder profile.
- **Per-module docs:**
  - [`apps/SBOM-XRay/README.md`](apps/SBOM-XRay/README.md) — SBOM lab; additional module context in [`apps/SBOM-XRay/.local/PROJECT-CONTEXT.md`](apps/SBOM-XRay/.local/PROJECT-CONTEXT.md).
  - [`apps/Log4j-Vulnerable/README.md`](apps/Log4j-Vulnerable/README.md) — Log4j / Log4Shell lab.
  - [`apps/MIL-STD-1553-Vulnerable/README.md`](apps/MIL-STD-1553-Vulnerable/README.md) — logistics portal, maintenance bridge, serial bus.
  - [`apps/splunk/README.md`](apps/splunk/README.md) — Splunk image, analytics, forwarder payloads.
- **Environment:** [`.env.example`](.env.example) — copy to `.env` at repo root (e.g. `SPLUNK_PASSWORD`).
- **Org-wide background** (not in this repo): stakeholder context and central docs live in **HAFB-Capstone-Project** and related org repositories (see Sections 3–4).

---

## 11. This Repository's Role — DEMO-FULL

**Repository:** **DEMO-FULL** (this monorepo).

**Role:** A **demonstration stack** that wires multiple Capstone training modules into **one** Docker Compose project started from the **repository root**. It is not the full Proxmox/Ansible lab; it is a portable slice for presenters and students to run on a laptop (Docker + Make + Bash). It includes:

| Module | Location | What it demonstrates |
|--------|----------|----------------------|
| **SBOM / supply chain** | `apps/SBOM-XRay/` | SBOM generation and analysis workflow (CLI inside `sbom-xray-lab`; isolated `sbom-lab` network). |
| **Log4j (exploited)** | `apps/Log4j-Vulnerable/` | Intentionally vulnerable Log4j 2.x services and a safe control service; Log4Shell-style training. |
| **MIL-STD-1553** | `apps/MIL-STD-1553-Vulnerable/` | Multi-zone scenario (portal, maintenance terminal, UDP serial bus) aligned to mission-relevant OT-style training. |
| **Blue team / monitoring** | `apps/splunk/` | Splunk Enterprise, payload server for forwarders, dashboards/rules under `apps/splunk/analytics/`. |

**Splunk status:** End-to-end Splunk monitoring is **Stable and Verified**. 
- **Telemetry**: All services (`log4j`, `mil1553`) report to Splunk via optimized Universal Forwarders.
- **Parsing**: Advanced parsing rules are implemented for multi-line Java logs and Flask web logs.
- **Filtering**: Automated "noise" filtering drops non-essential recurring logs (health checks, polling) at the indexer.
- **Initialization**: Robust initialization logic handles fresh volume creation and migration without loops.

**Agent focus:** Use the root **`Makefile`** for all operations. Orchestration is centralized in **`docker-compose.yaml`** using profiles (e.g., `forwarders`). Custom Splunk rules are managed in **`apps/splunk/analytics/rules/local/`** and mapped to the container. Prefer `make up`, `make down`, and `make validate` for stack lifecycle management.

---

*End of Project Context. Sections 1–9 describe the Capstone program and organization; Sections 10–11 describe this repository (DEMO-FULL).*
