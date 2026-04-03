# Architecture

## Two-objective architecture

This repo is designed around two separate but related subsystems:

1. `automation control plane`
2. `scoring and operator visibility`

The current MVP is focused on the first subsystem.

## Target topology

The intended Proxmox topology is:

- `Control VM`: hosts `hafb-range-control`, Ansible, reports, and later the scoring dashboard
- `ubuntuBlue`: analysis / blue-team target VM and first module deployment target
- `ubuntuVictim`: future vulnerable service target
- `kaliRed`: future red-team workstation
- `bastion`: optional network access or jump host depending on lab routing

The current MVP proves the automation pattern on `ubuntuBlue` first. The long-term architecture moves the automation and scoring responsibility onto a dedicated `Control VM`.

## MVP automation data flow

1. `SBOM-Training-Module` owns the actual Module 1 offline bundle.
2. `hafb-range-control` points Ansible at that extracted bundle.
3. Ansible stages the bundle on the Linux analysis VM.
4. Ansible runs the module's own offline installer.
5. Ansible runs the module's own offline validator.
6. The scoring script evaluates whether the deployed module is ready and assigns a simple readiness score.

## Air-gapped assumptions

The current design assumes:

- offline bundles already exist on disk
- Ansible and system packages come from approved internal sources
- the Control VM and target VMs can reach each other on the internal lab network
- no playbook step depends on public internet access

That is why the first module target is a prebuilt offline bundle rather than an installer that pulls dependencies at runtime.

## Future control-VM data flow

1. `Control VM` hosts `hafb-range-control`.
2. Ansible inventories define the target VMs.
3. The Control VM uses SSH to reach managed targets.
4. Deployment and validation are run from one place.
5. The future dashboard on the Control VM ingests Wazuh data and runs service checks across the lab.

## Recommended rollout stages

1. `Stage 1`: run the role directly on `ubuntuBlue` with `localhost`
2. `Stage 2`: create `controlOps` on Proxmox and prove SSH/Ansible connectivity to `ubuntuBlue`
3. `Stage 3`: run Module 1 deployment from `controlOps` to `ubuntuBlue`
4. `Stage 4`: add service checks and Wazuh-backed scoring on `controlOps`

## Why this structure

This keeps responsibilities clean:

- content stays in `SBOM-Training-Module`
- automation stays in `hafb-range-control`
- scoring and dashboard logic stay in `hafb-range-control`

That gives you a control repo that can later grow to include more modules without rewriting the module repos themselves.

## Current target

The only deployed target in this MVP is:

- `SBOM-Training-Module` Module 1 (`sbom-xray-lab`)

The intended runtime target for this MVP is `ubuntuBlue`.

## Planned scoring/dashboard path

The future scoring subsystem should:

- ingest Wazuh alerts from local or internal-only sources
- perform basic service-health checks for in-scope services
- display a lightweight web dashboard with score, alerts, and service state

That part is deliberately deferred until the Ansible deployment path is proven on one module.

## Future path

Later expansions can add:

- more Ansible roles for other modules
- a shared inventory for real Proxmox VMs managed from the Control VM
- a web scoring dashboard backed by Wazuh and service checks
- richer scoring rules tied to telemetry and service checks
