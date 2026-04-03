# HAFB Range Control

`hafb-range-control` is the Ansible automation repository for the Hill AFB capstone lab.

It is intended to be the central automation layer for:

- training modules
- vulnerable services or target workloads
- supporting host configuration tasks

The current reference implementation in this repository is:

1. deploy `SBOM-Training-Module` Module 1 (`sbom-xray-lab`) to a Linux analysis system with Ansible
2. validate the installed module using the module's offline validator

This repository is the control layer around the offline training bundle. It does not contain the training content itself. The content and installer come from `SBOM-Training-Module`.

Scoring and operator reporting are handled outside this repository.

If you need the plain-English walkthrough, start with [docs/how-it-works.md](docs/how-it-works.md).

## What This Repository Does

This repository is responsible for:

- managing inventories, playbooks, and roles for lab automation
- staging deployment artifacts on target hosts
- running repeatable deployment steps on managed systems
- running validation steps after deployment
- serving as the controller-side automation repo for additional modules or vulnerable services

This repository does not:

- rebuild module bundles
- host the student lab content source
- require internet access during runtime
- own scoring logic or dashboard logic

## Repository Model

The repository is organized around a reusable Ansible pattern:

1. inventory files define target systems and connection details
2. playbooks select a target group and a role
3. roles implement deployment and validation behavior
4. shell wrappers enforce explicit inventories and consistent execution

That pattern is reusable whether the target is:

- an offline training module
- a vulnerable application stack
- a host configuration task on `ubuntuBlue`, `ubuntuVictim`, or another managed VM

## Current Reference Implementation

The current implemented example is `SBOM-Training-Module` Module 1.

That implementation uses:

- `playbooks/deploy_sbom_module1.yml`
- `playbooks/validate_sbom_module1.yml`
- `roles/sbom_module1/`

The current runtime target is a Linux analysis VM such as `ubuntuBlue`.

The repository can still be run in two ways:

- directly on the Linux target with `inventories/localhost.yml`
- remotely from a control VM over SSH using a remote inventory

macOS is suitable for editing the repo and running limited checks, but the actual Module 1 installer and validator are Linux-targeted.

## Execution Flow

The generic control flow is:

1. the controller machine has the deployment artifacts or source files needed for a target
2. a wrapper script or `ansible-playbook` command launches the correct playbook
3. the playbook applies a role to the intended inventory group
4. the role performs deployment tasks on the target
5. the role performs validation tasks on the target

The current Module 1 implementation follows that pattern like this:

1. the controller machine has an extracted Module 1 offline bundle available on disk
2. `scripts/deploy.sh` runs `playbooks/deploy_sbom_module1.yml`
3. the `sbom_module1` role verifies the bundle on the controller and copies it to the target
4. the role normalizes expected file names, patches the staged installer for user-space install mode, and runs `install-module1-offline.sh`
5. `scripts/validate.sh` runs `playbooks/validate_sbom_module1.yml`
6. the role runs `validate-module1-offline.sh` on the target and stores a validation log

## Main Files

- `scripts/deploy.sh`: deploy wrapper for Ansible
- `scripts/validate.sh`: validation wrapper for Ansible
- `scripts/ping_targets.sh`: connectivity test for remote inventories
- `inventories/`: host definitions and connection settings
- `playbooks/`: top-level automation entrypoints
- `roles/`: reusable automation units for modules, services, or host tasks
- `playbooks/deploy_sbom_module1.yml`: deployment entrypoint
- `playbooks/validate_sbom_module1.yml`: validation entrypoint
- `roles/sbom_module1/tasks/deploy.yml`: bundle staging and installer execution
- `roles/sbom_module1/tasks/validate.yml`: validation execution and logging

## Configuration

By default, the repository looks for the extracted offline bundle at:

```text
/Users/taylorpreslar/capstone/SBOM-Training-Module/deploy/releases/Module1-offline-bundle-sbom-xray-2026-03-25_004519
```

Override that path with:

```bash
export SBOM_BUNDLE_SOURCE_DIR=/path/to/Module1-offline-bundle-sbom-xray
```

Important defaults:

- target staging directory: `~/hafb-staging/module1-offline-bundle`
- installed lab directory: `~/labs/sbom-Module1-sbom-xray`

These defaults belong to the current `sbom_module1` role. Additional roles can define their own defaults and target paths.

## Inventories

The repository includes:

- `inventories/localhost.yml`: local execution on the Linux target
- `inventories/proxmox-lab.yml`: current multi-VM lab inventory for the Proxmox environment

Although `ansible.cfg` defines a default inventory, the wrapper scripts still require an explicit `-i` inventory argument. This is intentional so deployment and validation always target the intended system.

As the repository grows, inventories can map different host groups for different automation categories, such as:

- `analysis`: training module targets
- `victim`: vulnerable service targets
- `red`: operator or red-team systems
- additional custom groups for service-specific automation

The current `inventories/proxmox-lab.yml` maps:

- `ubuntuBlue` at `192.168.86.37` with user `hafb`
- `ubuntuVictim` at `192.168.86.32` with user `hafb`
- `kaliRed` at `192.168.86.27` with user `kali`

For `kaliRed`, use SSH keys or `-k`/`--ask-pass` when needed. The password is not stored in the repository.

## Commands

### Run Directly On The Linux Target

```bash
cd ~/hafb-range-control
export SBOM_BUNDLE_SOURCE_DIR=/tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/localhost.yml
./scripts/validate.sh -i inventories/localhost.yml
```

### Run From A Control VM

```bash
cd ~/hafb-range-control
$EDITOR inventories/proxmox-lab.yml

./scripts/ping_targets.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
export SBOM_BUNDLE_SOURCE_DIR=~/bundles/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
./scripts/validate.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

In the remote-controller model, the extracted bundle must exist on the controller VM first. Ansible copies it from the controller to the target.

## Extending The Repository

This repository is designed to support more than the current Module 1 example.

Typical extension patterns are:

- add another training module role that stages a different offline bundle and runs that module's validator
- add a vulnerable service role that deploys an application, configuration, or container stack onto `ubuntuVictim`
- add a host-configuration role that installs tools, copies files, or enables services on a managed VM

For example, a future vulnerable-service role could:

1. copy application files or a Compose stack to `ubuntuVictim`
2. install dependencies from approved internal sources
3. start the vulnerable service
4. run a validation step such as an HTTP health check, open-port check, or service status check

For example, a future training-module role could:

1. stage a different offline lab bundle on `ubuntuBlue`
2. run the module installer
3. validate expected files, tools, or directories

The recommended implementation pattern for any new automation target is:

1. create a new role under `roles/<name>/`
2. put role-specific defaults in `defaults/main.yml`
3. separate deployment and validation tasks under `tasks/deploy.yml` and `tasks/validate.yml`
4. create top-level playbooks for that role
5. add or reuse inventory groups for the target systems
6. add a wrapper script only if the new target needs a dedicated entrypoint

## Generated Artifacts

Additional operational evidence written by deployment and validation includes:

- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_installed`
- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt`

Those files are specific to the current Module 1 example. Future roles can emit their own role-specific evidence files or logs.

## Make Targets

```bash
make help
make deploy INVENTORY=inventories/localhost.yml
make validate INVENTORY=inventories/localhost.yml
make demo INVENTORY=inventories/localhost.yml
```

## Repository Layout

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

## Documentation

- [docs/how-it-works.md](docs/how-it-works.md): plain-English walkthrough
- [docs/extending-the-repo.md](docs/extending-the-repo.md): how to add new modules or vulnerable services
- [docs/demo-runbook.md](docs/demo-runbook.md): demo command sequence and talking points
- [docs/architecture.md](docs/architecture.md): architecture and operating model
- [docs/control-vm-rollout.md](docs/control-vm-rollout.md): control VM setup guidance
- [docs/proxmox-testing.md](docs/proxmox-testing.md): Proxmox testing notes
