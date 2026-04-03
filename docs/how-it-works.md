# How It Works

This document is the plain-English explanation of `hafb-range-control`.

If the README is the short version, this is the "what is actually happening?" version.

## One-sentence summary

This repo is the control layer for your capstone lab: it uses Ansible to deploy one offline training module, validates that install, then scores whether the module is ready.

## The simplest mental model

Think of the project as three steps:

1. `deploy`
2. `validate`
3. `score`

That is the whole MVP.

## What this repo is

This repo is:

- an Ansible control repo
- a wrapper around an existing offline training bundle
- a place to store reports and future operator tooling

This repo is not:

- the training content itself
- a full cyber-range orchestrator yet
- the final Wazuh-backed dashboard

The actual training content lives in `SBOM-Training-Module`.

## The big picture

There are two separate ideas in the overall capstone:

1. automation
2. scoring and visibility

Right now, the repo is mostly proving the first idea.

The score report exists because it helps show the direction of the second idea, but the current MVP is still automation-first.

## The current MVP flow

Here is the real flow from start to finish:

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
11. You run `./scripts/score.sh`.
12. The Python scoring script checks the installed lab and writes reports into `reports/`.

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

### `scripts/score.sh`

This is the scoring entrypoint.

It simply runs:

```bash
python3 scoring/score_module1.py
```

### `scoring/score_module1.py`

This script reads the scoring rules from `scoring/weights.json`, performs each readiness check, calculates a score, and writes:

- `reports/module1-score-latest.json`
- `reports/module1-score-latest.md`

The current checks are intentionally basic:

- does the offline bundle exist
- does the installed lab directory exist
- are the expected student artifacts present
- were instructor materials copied
- is `syft` available
- is `jq` available
- does the compatibility symlink exist
- does the official validator pass

## Why the repo uses explicit inventories

The wrapper scripts force you to pass `-i` even though `ansible.cfg` has a default inventory.

That is a safety feature.

Without that guard, if you were on the future Control VM and ran deploy by mistake, Ansible could target the controller itself through `inventories/localhost.yml`.

So the repo makes you be explicit.

## Why `ubuntuBlue` is the first target

`SBOM-Training-Module` Module 1 is Linux-targeted. The installer and tooling are meant to run on a Linux analysis VM.

That makes `ubuntuBlue` the best first proof target because:

- it matches the module runtime
- it keeps the first demo simple
- it avoids mixing SSH issues with installer issues

For the capstone, the clean first milestone is:

1. copy the repo to `ubuntuBlue`
2. point at the offline bundle in `/tmp`
3. run deploy
4. run validate
5. run score

## Why there is a Control VM plan

Running directly on `ubuntuBlue` is the easiest first proof.

Running from a dedicated `controlOps` VM is the next architectural step.

That future model is:

- one control VM hosts `hafb-range-control`
- that VM runs Ansible to other lab systems
- that same VM can later host scoring and dashboard services

So the capstone story has a simple progression:

1. prove the pattern locally on one Linux target
2. move the control logic onto a dedicated VM
3. expand to more targets and richer scoring

## What the reports mean

The reports in `reports/` are not trying to be a final cyber dashboard.

They are proof that the control repo can convert deployment state into something measurable.

That matters for the capstone because it shows the repo is not just pushing files. It is also evaluating readiness.

## What to say in your capstone

If you need a short explanation, say this:

- `SBOM-Training-Module` contains the actual lab content
- `hafb-range-control` is the automation and scoring layer for that content
- the MVP deploys one module with Ansible, validates it, and scores readiness
- the design is meant to grow into a central control VM and future dashboard

## Common confusion points

### "Why does this repo point to another repo?"

Because this repo is not the module itself. It controls deployment of the offline bundle produced by `SBOM-Training-Module`.

### "Why is scoring separate from validation?"

Validation answers "did the module's official validator pass?"

Scoring answers "how ready is the overall environment based on multiple checks?"

### "Why not just run the installer manually?"

Because the capstone goal is to prove centralized automation and repeatable deployment, not just one manual install.

### "Why is the dashboard not here yet?"

Because the MVP is proving the automation path first. The dashboard is a later phase once the control pattern works.

## Recommended reading order

If you want the shortest path to understanding the repo, read in this order:

1. `README.md`
2. this file
3. `docs/demo-runbook.md`
4. `docs/architecture.md`
