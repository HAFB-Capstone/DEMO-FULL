# Architecture

## Repository role

`hafb-range-control` is the automation control plane for deploying and validating supported lab modules with Ansible.

## Target topology

The intended Proxmox topology is:

- `Control VM`: hosts `hafb-range-control` and Ansible
- `ubuntuBlue`: analysis / blue-team target VM and first module deployment target
- `ubuntuVictim`: future vulnerable service target
- `kaliRed`: future red-team workstation
- `bastion`: optional network access or jump host depending on lab routing

The first supported deployment target is `ubuntuBlue`. The long-term architecture moves Ansible execution onto a dedicated `Control VM`.

## Automation data flow

1. `SBOM-Training-Module` owns the actual Module 1 offline bundle.
2. `hafb-range-control` points Ansible at that extracted bundle.
3. Ansible stages the bundle on the Linux analysis VM.
4. Ansible runs the module's own offline installer.
5. Ansible runs the module's own offline validator.

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

## Recommended rollout stages

1. `Stage 1`: run the role directly on `ubuntuBlue` with `localhost`
2. `Stage 2`: create `controlOps` on Proxmox and prove SSH/Ansible connectivity to `ubuntuBlue`
3. `Stage 3`: run Module 1 deployment from `controlOps` to `ubuntuBlue`

## Why this structure

This keeps responsibilities clean:

- content stays in `SBOM-Training-Module`
- automation stays in `hafb-range-control`
- scoring and dashboard logic stay outside this repository

That gives you a control repo that can later grow to include more modules without rewriting the module repos themselves.

## Current target

The only deployed target in the current implementation is:

- `SBOM-Training-Module` Module 1 (`sbom-xray-lab`)

The intended runtime target is `ubuntuBlue`.

## Future path

Later expansions can add:

- more Ansible roles for other modules
- a shared inventory for real Proxmox VMs managed from the Control VM
- additional automation for more lab systems
