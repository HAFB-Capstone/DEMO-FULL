# HAFB Range Control

`hafb-range-control` is the Ansible automation repository for the Hill AFB capstone lab.

It performs one supported workflow:

1. deploy `SBOM-Training-Module` Module 1 (`sbom-xray-lab`) to a Linux analysis system with Ansible
2. validate the installed module using the module's offline validator

This repository is the control layer around the offline training bundle. It does not contain the training content itself. The content and installer come from `SBOM-Training-Module`.

Scoring and operator reporting are handled outside this repository.

If you need the plain-English walkthrough, start with [docs/how-it-works.md](docs/how-it-works.md).

## What This Repository Does

This repository is responsible for:

- Ansible-based deployment of the Module 1 offline bundle
- execution of the module's validation script on the target system
- staging the bundle on the target host
- running the module's installer and validator in a repeatable way

This repository does not:

- rebuild the Module 1 bundle
- host the student lab content source
- require internet access during runtime
- own scoring logic or dashboard logic

## Supported Target

The supported runtime target is a Linux analysis VM such as `ubuntuBlue`.

The repository can be run in two ways:

- directly on the Linux target with `inventories/localhost.yml`
- remotely from a control VM over SSH using a remote inventory

macOS is suitable for editing the repo and running limited checks, but the actual Module 1 installer and validator are Linux-targeted.

## Execution Flow

The operational flow is:

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

## Inventories

The repository includes:

- `inventories/localhost.yml`: local execution on the Linux target
- `inventories/ubuntuBlue.example.yml`: example remote inventory for one analysis host
- `inventories/proxmox-lab.example.yml`: example remote inventory for a multi-VM lab

Although `ansible.cfg` defines a default inventory, the wrapper scripts still require an explicit `-i` inventory argument. This is intentional so deployment and validation always target the intended system.

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
cp inventories/proxmox-lab.example.yml inventories/proxmox-lab.yml
$EDITOR inventories/proxmox-lab.yml

./scripts/ping_targets.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
export SBOM_BUNDLE_SOURCE_DIR=~/bundles/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
./scripts/validate.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

In the remote-controller model, the extracted bundle must exist on the controller VM first. Ansible copies it from the controller to the target.

## Generated Artifacts

Additional operational evidence written by deployment and validation includes:

- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_installed`
- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt`

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
├── roles/sbom_module1/
└── scripts/
```

## Documentation

- [docs/how-it-works.md](docs/how-it-works.md): plain-English walkthrough
- [docs/demo-runbook.md](docs/demo-runbook.md): demo command sequence and talking points
- [docs/architecture.md](docs/architecture.md): architecture and operating model
- [docs/control-vm-rollout.md](docs/control-vm-rollout.md): control VM setup guidance
- [docs/proxmox-testing.md](docs/proxmox-testing.md): Proxmox testing notes
