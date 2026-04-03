# HAFB Range Control

`hafb-range-control` is the control-plane repo for the Hill AFB capstone lab.

Its current MVP is intentionally small:

1. deploy `SBOM-Training-Module` Module 1 with Ansible
2. validate the install on a Linux target
3. generate a simple readiness score report

This repo does not own the training content itself. The content and offline installer live in `SBOM-Training-Module`. This repo is the automation and scoring layer around that content.

If you need the plain-English version first, start with [docs/how-it-works.md](docs/how-it-works.md).

## What this repo proves

The capstone proof is straightforward:

- one central repo can automate one air-gapped module end to end
- deployment can be validated consistently
- the result can be turned into a readiness score
- the same control repo can later expand to more modules and a dashboard

## Current scope

Right now this repo supports one target only:

- `SBOM-Training-Module` Module 1 (`sbom-xray-lab`)

The runtime target for deploy and validate is a Linux VM such as `ubuntuBlue`. macOS is fine for writing the repo, reading docs, and running limited checks, but the actual module installer is Linux-targeted.

## How it works

The end-to-end flow is:

1. Ansible reads an extracted Module 1 offline bundle from the controller machine.
2. The `sbom_module1` role copies that bundle to the target VM.
3. The role runs the module's own installer: `install-module1-offline.sh`.
4. The role runs the module's own validator: `validate-module1-offline.sh`.
5. `scoring/score_module1.py` checks the installed lab and writes score reports to `reports/`.

In other words: this repo does not rebuild Module 1. It automates the existing offline bundle and scores the result.

## Repo layout

```text
hafb-range-control/
├── README.md                     # Short project overview and usage
├── Makefile                      # Simple wrappers for deploy, validate, and score
├── ansible.cfg                   # Default Ansible configuration
├── docs/                         # Architecture, runbooks, and walkthrough docs
├── inventories/                  # Localhost and remote inventory files
├── playbooks/                    # Top-level deployment, validation, and connectivity playbooks
├── reports/                      # Generated score outputs
├── roles/sbom_module1/           # The Ansible role for SBOM Module 1
├── scoring/                      # Readiness scoring script and weights
└── scripts/                      # Convenience wrappers around Ansible and scoring
```

## Important files

- `scripts/deploy.sh`: runs the deploy playbook
- `scripts/validate.sh`: runs the validation playbook
- `scripts/score.sh`: runs the Python scoring script
- `playbooks/deploy_sbom_module1.yml`: deploy entrypoint
- `playbooks/validate_sbom_module1.yml`: validation entrypoint
- `roles/sbom_module1/tasks/deploy.yml`: bundle staging and install logic
- `roles/sbom_module1/tasks/validate.yml`: validation logic
- `scoring/score_module1.py`: readiness scoring logic

## Default paths and variables

By default, the repo looks for the extracted offline bundle at:

```text
/Users/taylorpreslar/capstone/SBOM-Training-Module/deploy/releases/Module1-offline-bundle-sbom-xray-2026-03-25_004519
```

Override that path when needed:

```bash
export SBOM_BUNDLE_SOURCE_DIR=/path/to/Module1-offline-bundle-sbom-xray
```

Other important defaults:

- target staging directory: `~/hafb-staging/module1-offline-bundle`
- installed lab directory: `~/labs/sbom-Module1-sbom-xray`
- score reports: `reports/module1-score-latest.json` and `reports/module1-score-latest.md`

## Inventories

The repo ships with:

- `inventories/localhost.yml`: for running directly on the Linux target VM
- `inventories/ubuntuBlue.example.yml`: example single-target remote inventory
- `inventories/proxmox-lab.example.yml`: example multi-VM Proxmox inventory

Even though `ansible.cfg` defaults to `inventories/localhost.yml`, the wrapper scripts still require an explicit `-i` inventory argument. That guard is intentional so you do not accidentally deploy to the wrong machine.

## Quick start

### Recommended first proof: run directly on `ubuntuBlue`

This is the simplest and cleanest capstone path.

```bash
cd ~/hafb-range-control
export SBOM_BUNDLE_SOURCE_DIR=/tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/localhost.yml
./scripts/validate.sh -i inventories/localhost.yml
./scripts/score.sh
```

This assumes:

- the repo has been copied to `ubuntuBlue`
- the Module 1 bundle is already staged in `/tmp`
- Ansible is installed on `ubuntuBlue`

### Next step: run from a dedicated Control VM

After the localhost proof works, move to the intended architecture:

```bash
cd ~/hafb-range-control
cp inventories/proxmox-lab.example.yml inventories/proxmox-lab.yml
$EDITOR inventories/proxmox-lab.yml

./scripts/ping_targets.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
export SBOM_BUNDLE_SOURCE_DIR=~/bundles/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
./scripts/validate.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

In that model, the extracted bundle must exist on the controller VM first. Ansible copies it from the controller to the target.

## Score output

The scoring script checks:

- bundle source exists
- installed lab directory exists
- required student artifacts exist
- instructor materials exist
- `syft` is on `PATH`
- `jq` is on `PATH`
- `~/labs/sbom-xray` compatibility symlink exists
- the official Module 1 validator passes

It writes:

- `reports/module1-score-latest.json`
- `reports/module1-score-latest.md`

## Make targets

You can use the shell wrappers directly, or use `make`:

```bash
make help
make deploy INVENTORY=inventories/localhost.yml
make validate INVENTORY=inventories/localhost.yml
make score
```

## Documentation

- [docs/how-it-works.md](docs/how-it-works.md): plain-English project walkthrough
- [docs/demo-runbook.md](docs/demo-runbook.md): capstone demo sequence
- [docs/architecture.md](docs/architecture.md): current and future architecture
- [docs/control-vm-rollout.md](docs/control-vm-rollout.md): Control VM setup plan
- [docs/proxmox-testing.md](docs/proxmox-testing.md): Proxmox testing notes
- [docs/mvp.md](docs/mvp.md): short MVP definition

## Capstone explanation

The cleanest way to describe this repo is:

- `SBOM-Training-Module` owns the training content and installer
- `hafb-range-control` owns automation, validation orchestration, and scoring
- the current MVP proves the pattern on one module first
- later phases can add more modules, more targets, and a dashboard
