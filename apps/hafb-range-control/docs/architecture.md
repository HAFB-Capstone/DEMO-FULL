# Architecture

## Repository Role

`hafb-range-control` is the controller-side automation plane for the lab.

It is designed to support multiple automation categories:

- training modules
- vulnerable services
- supporting host configuration tasks

## Topology

The current Proxmox-oriented topology is:

- `Control VM`: hosts `hafb-range-control` and Ansible
- `ubuntuBlue`: analysis / blue-team target VM
- `ubuntuVictim`: vulnerable service target
- `kaliRed`: future red-team workstation
- `bastion`: optional network access or jump host depending on lab routing

The active inventory already maps `ubuntuBlue`, `ubuntuVictim`, and `kaliRed` into separate host groups so they can receive different automation roles.

## Control-Plane Model

1. inventories define which hosts belong to each automation category
2. playbooks select a host group and a role
3. roles implement deployment, validation, and optional reset logic
4. the control VM or local target executes the playbook
5. validation artifacts are written on the managed host

This model keeps the control layer stable even when the managed targets differ.

## Host Groups

The current inventory structure separates hosts by automation purpose:

- `analysis`: training modules and blue-team support tasks
- `victim`: vulnerable services and application targets
- `red`: red-team or operator-side support systems

That grouping makes it straightforward to target the correct machines with `--limit` or host-group-specific playbooks.

## Lifecycle Pattern

Every automation target in this repository should follow the same lifecycle:

1. provision
2. validate
3. reset when the target requires controlled reversion

For example:

- a training module may provision a lab bundle and validate required files or tools
- a vulnerable service may provision an application stack and validate service health
- a host-preparation role may provision tooling and validate system state

Reset can be implemented in two ways:

- service-level reset inside a target-specific Ansible role
- infrastructure-level reset through VM snapshot rollback

## Current Reference Implementation

The current implemented example is `sbom_module1`.

It is important as a reference implementation because it already demonstrates the repository pattern:

1. controller-side artifact selection
2. role-based deployment on a managed host
3. role-based validation after deployment
4. evidence written back to the target host

## Air-Gapped Assumptions

The current design assumes:

- offline bundles already exist on disk
- Ansible and system packages come from approved internal sources
- the Control VM and target VMs can reach each other on the internal lab network
- no playbook step depends on public internet access

That assumption applies equally to module bundles and vulnerable-service dependencies.

## Control VM Role

1. `Control VM` hosts `hafb-range-control`.
2. Ansible inventories define the target VMs.
3. The Control VM uses SSH to reach managed targets.
4. Playbooks run from one place against whichever VM group needs automation.

## Why This Structure

This keeps responsibilities clean:

- automation stays in `hafb-range-control`
- content stays with the module or service source repository
- scoring and dashboard logic stay outside this repository

That separation makes it practical to add new roles without turning this repository into a copy of every managed workload.

## Extending The Architecture

Examples of future additions that fit this structure:

- another training module staged onto `ubuntuBlue`
- a vulnerable web application or service deployed onto `ubuntuVictim`
- a sensor, agent, or support tool installed on one or more managed hosts

Each of those additions would follow the same basic model:

1. create a new role
2. create deploy, validate, and reset playbooks when needed
3. target the correct inventory group
4. keep role-specific defaults and artifacts isolated from other automation targets
