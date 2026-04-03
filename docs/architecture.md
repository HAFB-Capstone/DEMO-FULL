# Architecture

## Repository role

`hafb-range-control` is the automation control plane for deploying and validating supported lab modules with Ansible.

It is designed to support multiple automation categories:

- training modules
- vulnerable services
- supporting host configuration tasks

## Target topology

The intended Proxmox topology is:

- `Control VM`: hosts `hafb-range-control` and Ansible
- `ubuntuBlue`: analysis / blue-team target VM and first module deployment target
- `ubuntuVictim`: future vulnerable service target
- `kaliRed`: future red-team workstation
- `bastion`: optional network access or jump host depending on lab routing

The first implemented deployment target is `ubuntuBlue`. The long-term architecture moves Ansible execution onto a dedicated `Control VM`.

## Generic automation model

1. inventories define which hosts belong to each automation category
2. playbooks select a host group and a role
3. roles implement deployment and validation logic
4. the control VM or local target executes the playbook
5. validation artifacts are written on the managed host

## Current reference implementation

The current implemented example is `sbom_module1`.

Its flow is:

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

That is why the current example target is a prebuilt offline bundle rather than an installer that pulls dependencies at runtime.

## Future control-VM data flow

1. `Control VM` hosts `hafb-range-control`.
2. Ansible inventories define the target VMs.
3. The Control VM uses SSH to reach managed targets.
4. Deployment and validation are run from one place.

## Automation categories in this design

The same architecture can manage different kinds of targets:

- `analysis` hosts for training modules
- `victim` hosts for vulnerable applications or services
- `red` hosts for operator tooling or red-team preparation
- additional groups for service-specific or environment-specific automation

## Recommended rollout stages

1. `Stage 1`: run the role directly on `ubuntuBlue` with `localhost`
2. `Stage 2`: create `controlOps` on Proxmox and prove SSH/Ansible connectivity to `ubuntuBlue`
3. `Stage 3`: run Module 1 deployment from `controlOps` to `ubuntuBlue`
4. `Stage 4`: add more roles for additional modules or vulnerable services

## Why this structure

This keeps responsibilities clean:

- content stays in `SBOM-Training-Module`
- automation stays in `hafb-range-control`
- scoring and dashboard logic stay outside this repository

That gives you a control repo that can later grow to include more modules without rewriting the module repos themselves.

## Extending the architecture

Examples of future additions that fit this structure:

- another training module staged onto `ubuntuBlue`
- a vulnerable web application or service deployed onto `ubuntuVictim`
- a sensor, agent, or support tool installed on one or more managed hosts

Each of those additions would follow the same basic model:

1. create a new role
2. create deploy and validate playbooks
3. target the correct inventory group
4. keep role-specific defaults and artifacts isolated from other automation targets

## Current target

The only deployed target in the current implementation is:

- `SBOM-Training-Module` Module 1 (`sbom-xray-lab`)

The intended runtime target is `ubuntuBlue`.

## Future path

Later expansions can add:

- more Ansible roles for other modules
- a shared inventory for real Proxmox VMs managed from the Control VM
- additional automation for more lab systems
