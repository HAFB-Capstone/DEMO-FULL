# How It Works

This document is the plain-English explanation of `hafb-range-control`.

If the README is the short version, this is the "what is actually happening?" version.

## One-sentence summary

This repo is the Ansible control layer for your capstone lab: it provides a reusable pattern for deploying and validating training modules, vulnerable services, and related host automation.

## The simplest mental model

Think of the project as two steps:

1. `deploy`
2. `validate`

That is the entire supported workflow in this repository.

## What this repo is

This repo is:

- an Ansible control repo
- a place to keep deployment and validation automation together
- a reusable structure for additional modules or target services

This repo is not:

- the training content itself
- the scoring repository
- the dashboard repository

The actual training content lives in `SBOM-Training-Module`.

## Scope

This repository is scoped to automation.

Its job is to deploy and validate supported targets. Scoring and operator visibility are handled outside this repository.

## Generic repository pattern

At a high level, the repository works like this:

1. `inventories/` defines which systems Ansible can target
2. `playbooks/` defines the entrypoints for a specific automation action
3. `roles/` contains the actual deploy and validate logic
4. `scripts/` wraps playbook execution so operators use a consistent command pattern

That pattern works whether the target is:

- a training module on an analysis VM
- a vulnerable service on a victim VM
- a system configuration task on a managed host

## Current reference implementation

The current concrete implementation in the repo is `sbom_module1`, which deploys and validates `SBOM-Training-Module` Module 1.

## The current implementation flow

Here is the current example flow from start to finish:

1. You place an extracted Module 1 offline bundle on the machine running Ansible.
2. You run `./scripts/deploy.sh` with an inventory.
3. Ansible loads `playbooks/deploy_sbom_module1.yml`.
4. That playbook applies the `sbom_module1` role to the `analysis` host group.
5. The role checks that the bundle exists on the controller.
6. The role copies the bundle to a staging directory on the target VM.
7. The role patches the staged installer so the install can run without requiring privileged package installation.
8. The role runs the module's own installer script.
9. You run `./scripts/validate.sh` with the same inventory.
10. Ansible runs the module's own validator on the target VM.

## The control flow by file

The easiest way to understand the repo is to follow the main entrypoints.

### `scripts/deploy.sh`

This is the normal deploy command.

It does three simple things:

- makes sure `ansible-playbook` exists
- requires you to pass an explicit inventory
- runs `playbooks/deploy_sbom_module1.yml`

### `playbooks/deploy_sbom_module1.yml`

This playbook targets the `analysis` group and sets:

- `sbom_mode: deploy`

That variable tells the role to use its deploy tasks.

### `roles/sbom_module1/tasks/deploy.yml`

This is the real deployment logic.

It:

1. confirms the bundle exists on the controller machine
2. confirms the target machine is Linux
3. checks that the installer script exists in the bundle
4. creates a staging directory on the target
5. copies the offline bundle into that staging directory
6. normalizes a student file naming mismatch
7. patches the installer to support user-space install mode
8. removes the patched installer from the checksum manifest
9. runs `install-module1-offline.sh`
10. writes an install stamp file

This is why the repo can stay simple: it reuses the module's existing offline installer instead of reimplementing the module.

### `scripts/validate.sh`

This wrapper is the same idea as deploy:

- check Ansible exists
- require an explicit inventory
- run `playbooks/validate_sbom_module1.yml`

### `roles/sbom_module1/tasks/validate.yml`

This file handles validation.

It:

1. checks the validator script exists in the staged bundle
2. confirms the target is Linux
3. confirms the installed lab directory exists
4. runs `validate-module1-offline.sh`
5. writes a local validation log into the lab directory

## How this applies to new modules or vulnerable services

The same repository pattern can be reused for other targets.

### Additional training module

A future training-module role would normally:

1. accept a bundle path or source directory
2. copy the bundle to the correct target host
3. run that module's installer
4. run that module's validator or post-install checks

### Vulnerable service or lab target

A future vulnerable-service role would normally:

1. target a host such as `ubuntuVictim`
2. copy application files, a container stack, or configuration
3. install required packages from approved internal sources
4. start the service
5. validate that the service is reachable or configured as expected

Validation for a vulnerable service might be:

- `systemctl status`
- container health checks
- an HTTP response check
- an open-port check
- a file or configuration check

## How to add a new automation target

The clean pattern is:

1. create a new role under `roles/<target_name>/`
2. add role defaults in `defaults/main.yml`
3. split the tasks into `tasks/deploy.yml` and `tasks/validate.yml`
4. add a top-level deploy playbook and validate playbook
5. add or update inventory groups for the systems that should receive that automation
6. add a wrapper script only if the target needs a dedicated operator command

That gives you a structure that scales without mixing every lab task into one large playbook.

## Why the repo uses explicit inventories

The wrapper scripts force you to pass `-i` even though `ansible.cfg` has a default inventory.

That is a safety feature.

Without that guard, if you were on the future Control VM and ran deploy by mistake, Ansible could target the controller itself through `inventories/localhost.yml`.

So the repo makes you be explicit.

## Why `ubuntuBlue` is the first target example

`SBOM-Training-Module` Module 1 is Linux-targeted. The installer and tooling are meant to run on a Linux analysis VM.

That makes `ubuntuBlue` the best first proof target because:

- it matches the module runtime
- it keeps the first demo simple
- it avoids mixing SSH issues with installer issues

For the capstone, the simplest operating sequence is:

1. copy the repo to `ubuntuBlue`
2. point at the offline bundle in `/tmp`
3. run deploy
4. run validate

## Why there is a Control VM plan

Running directly on `ubuntuBlue` is the easiest first proof.

Running from a dedicated `controlOps` VM is the next architectural step.

That future model is:

- one control VM hosts `hafb-range-control`
- that VM runs Ansible to other lab systems

The deployment model has a simple progression:

1. prove the pattern locally on one Linux target
2. move the control logic onto a dedicated VM
3. expand to more targets and more Ansible-managed modules

## What files this repo creates

On the target system, deployment and validation create:

- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_installed`
- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt`

## What to say in your capstone

If you need a short explanation, say this:

- `SBOM-Training-Module` contains the actual lab content
- `hafb-range-control` is the reusable Ansible automation layer for deploying and validating lab targets
- the current reference implementation stages the Module 1 bundle, runs the installer, and runs the validator
- the same structure can be reused for additional modules or vulnerable services
- scoring is handled in a separate repository

## Common confusion points

### "Why does this repo point to another repo?"

Because this repo is the automation layer, not the content layer. In the current implementation it automates the offline bundle produced by `SBOM-Training-Module`.

### "Is this repo only for Module 1?"

No. Module 1 is the current implemented example. The repository structure is meant to support additional training modules, vulnerable services, and other Ansible-managed lab tasks.

### "Why not just run the installer manually?"

Because the capstone goal is to prove centralized automation and repeatable deployment, not just one manual install.

### "Where is scoring?"

Scoring is handled outside this repository. `hafb-range-control` stops at deployment and validation.

## Recommended reading order

If you want the shortest path to understanding the repo, read in this order:

1. `README.md`
2. this file
3. `docs/demo-runbook.md`
4. `docs/architecture.md`
