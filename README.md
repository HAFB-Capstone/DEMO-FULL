# HAFB Range Control

`hafb-range-control` is the central Ansible automation repository for the Hill AFB range environment.

Its purpose is to automate controller-side operations across the lab VMs, including:

- provisioning training modules
- provisioning vulnerable services or target workloads
- validating deployed systems after automation runs
- orchestrating reset workflows when a target-specific reset playbook exists
- maintaining a single inventory and execution model for the range

This repository is intentionally focused on automation. It does not own scoring, dashboards, or the source content of the individual lab modules.

## Repository Purpose

The repository is designed to solve one problem consistently:

use a single Ansible control repo to manage repeatable lifecycle operations across multiple VMs.

Those lifecycle operations are:

1. provision
2. validate
3. reset when required

In practice, that means this repo is where you define:

- which systems exist in the range
- which systems belong to which automation groups
- which playbooks run for each target type
- which roles implement deploy, validate, and reset behavior

## Automation Model

The repository uses a simple Ansible pattern:

1. `inventories/` defines hosts and host groups
2. `playbooks/` defines top-level automation entrypoints
3. `roles/` contains the actual deployment, validation, and optional reset logic
4. `scripts/` provides consistent wrappers around `ansible-playbook`

That pattern is generic enough to support:

- training modules on analysis hosts
- vulnerable applications on victim hosts
- host configuration and support tooling on any managed VM

## Current Lab Inventory

The active Proxmox inventory is [proxmox-lab.yml](/Users/taylorpreslar/capstone/hafb-range-control/inventories/proxmox-lab.yml#L1).

It currently maps:

- `ubuntuBlue` in the `analysis` group at `192.168.86.37` with user `hafb`
- `ubuntuVictim` in the `victim` group at `192.168.86.32` with user `hafb`
- `kaliRed` in the `red` group at `192.168.86.27` with user `kali`

`kaliRed` is a Kali system, not Ubuntu. Its password is intentionally not stored in the repository. Use SSH keys or `-k` / `--ask-pass` when password authentication is required.

The local-only inventory in [localhost.yml](/Users/taylorpreslar/capstone/hafb-range-control/inventories/localhost.yml#L1) is useful when automation is run directly on a target VM.

## Current Implemented Example

The current implemented example in this repository is the `sbom_module1` role.

It demonstrates the repository pattern by:

- staging an offline training bundle from the controller to the target
- running the target module's installer
- running the target module's validator
- writing evidence files on the managed host

That implementation is an example of the automation pattern, not the limit of the repository.

## How The Repository Is Used

### Connectivity

Use the connectivity playbook to confirm SSH reachability and fact gathering across the lab:

```bash
./scripts/ping_targets.sh -i inventories/proxmox-lab.yml
./scripts/ping_targets.sh -i inventories/proxmox-lab.yml --limit ubuntuVictim
```

### Provisioning

Provisioning is implemented by target-specific deploy playbooks.

The current example is:

```bash
./scripts/deploy.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

Future vulnerable-service roles would follow the same pattern, for example:

```bash
./scripts/run_playbook.sh playbooks/deploy_vulnerable_webapp.yml -i inventories/proxmox-lab.yml --limit ubuntuVictim
```

### Validation

Validation is implemented by target-specific validate playbooks.

The current example is:

```bash
./scripts/validate.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

The same command pattern applies to future roles:

```bash
./scripts/run_playbook.sh playbooks/validate_vulnerable_webapp.yml -i inventories/proxmox-lab.yml --limit ubuntuVictim
```

### Reset

Reset is a supported automation pattern for this repository, even though no generic reset playbook is shipped yet.

There are two practical reset models:

- service-level reset: a role-specific reset playbook removes files, restores configuration, reseeds data, or restarts services
- VM-level reset: the environment is reverted through a Proxmox snapshot or another infrastructure-level rollback mechanism

When a target needs service-level reset automation, add a `reset` playbook and invoke it through the generic runner:

```bash
./scripts/run_playbook.sh playbooks/reset_vulnerable_webapp.yml -i inventories/proxmox-lab.yml --limit ubuntuVictim
```

This is the recommended pattern for vulnerable services that need repeatable cleanup between exercises.

## Commands

The repository currently provides these operator entrypoints:

- [deploy.sh](/Users/taylorpreslar/capstone/hafb-range-control/scripts/deploy.sh#L1): runs the current deploy playbook
- [validate.sh](/Users/taylorpreslar/capstone/hafb-range-control/scripts/validate.sh#L1): runs the current validate playbook
- [ping_targets.sh](/Users/taylorpreslar/capstone/hafb-range-control/scripts/ping_targets.sh#L1): checks managed-host connectivity
- [run_playbook.sh](/Users/taylorpreslar/capstone/hafb-range-control/scripts/run_playbook.sh#L1): runs any playbook in the repo with the same inventory safety guard

The wrappers require an explicit `-i` inventory argument. This avoids accidentally running automation against the controller because `ansible.cfg` defaults to `inventories/localhost.yml`.

## Adding New Automation Targets

To add a new training module, vulnerable service, or host task:

1. add or update the relevant host group in `inventories/proxmox-lab.yml`
2. create a new role under `roles/<target_name>/`
3. keep role variables in `defaults/main.yml`
4. separate lifecycle tasks into `tasks/deploy.yml`, `tasks/validate.yml`, and `tasks/reset.yml` when reset is needed
5. create top-level playbooks such as `deploy_<target>.yml`, `validate_<target>.yml`, and `reset_<target>.yml`
6. run those playbooks with `scripts/run_playbook.sh`

This keeps each automation target isolated and makes it possible to provision or reset one service without affecting unrelated systems.

## Vulnerable-Service Use Case

For a vulnerable service on `ubuntuVictim`, this repository would typically be used to:

1. copy application code, configuration, or a container stack to `ubuntuVictim`
2. install dependencies from approved internal sources
3. start the vulnerable workload
4. validate service health with `systemctl`, container checks, HTTP checks, or port checks
5. reset the workload by removing data, restoring baseline config, or re-running a reset playbook

That is the same lifecycle model the repository already uses for module automation. The target changes, but the control pattern stays the same.

## Current Repository Layout

```text
hafb-range-control/
├── README.md
├── Makefile
├── ansible.cfg
├── docs/
├── inventories/
├── playbooks/
├── roles/
└── scripts/
```

## Remaining Documentation

- [architecture.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/architecture.md#L1): environment and control-plane design
- [extending-the-repo.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/extending-the-repo.md#L1): patterns for adding new modules, services, and reset playbooks
