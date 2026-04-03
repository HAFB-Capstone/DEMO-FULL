# HAFB Range Control

`hafb-range-control` is the control repo for the Hill AFB capstone environment. It is organized around two project objectives:

- objective 1: infrastructure automation for training modules and vulnerable systems
- objective 2: scoring and operator visibility for the training environment

The current MVP is intentionally centered on objective 1. It includes:

- a minimal Ansible deployment path
- a simple readiness scoring layer
- one concrete proof-of-concept target: `SBOM-Training-Module` Module 1 (`sbom-xray-lab`)
- a path toward a dedicated Control VM architecture on Proxmox

This repo is intentionally narrow. It does not try to orchestrate the entire cyber range yet. The goal is to prove that:

1. a central control repo can deploy one training module with Ansible
2. the deployed module can be validated consistently
3. a basic scoring process can evaluate whether that module is ready for use
4. the control repo structure can later expand into a real scoring dashboard and additional modules

## Scope of the MVP

This repo currently handles only one service/module:

- `SBOM-Training-Module` Module 1 offline bundle (`sbom-xray-lab`)

The deploy path reuses the existing offline installer already shipped by the SBOM repo. Ansible stages that bundle on the target and runs the installer. The scoring script then checks that the lab exists, required files are present, tools are installed, and the module validator passes.

The dashboard/scoring objective is present only as an early foundation right now. The long-term intent is:

- ingest Wazuh alerts from internal sources
- perform basic service checks
- expose a small web dashboard for operators or evaluators

That is not the current MVP. The current MVP is Ansible-first.

## Target environment

The actual Module 1 bundle is meant to run on a Linux analysis VM such as `ubuntuBlue`. The bundle includes Linux binaries like `syft`, so the full deploy and validate flow should run on Linux.

macOS is still useful for:

- writing and reviewing the control repo
- running playbook syntax checks
- running the scoring script logic

But the real install target should be Linux.

For the first real MVP test, the simplest path is:

1. copy this repo to `ubuntuBlue`
2. use the local `localhost` inventory on that VM
3. point Ansible at the already-staged Module 1 bundle in `/tmp`
4. run deploy, validate, and score directly on `ubuntuBlue`

That avoids unnecessary SSH complexity and fits the air-gapped model better.

The next step after that proof is a dedicated `Control VM`:

1. create a Linux VM on Proxmox whose only job is automation and scoring
2. host `hafb-range-control` on that VM
3. run Ansible from that VM to `ubuntuBlue`, `ubuntuVictim`, and later other targets
4. run the future scoring dashboard on that same VM

## Implementation order

Build this in three steps:

1. `Phase 1`: prove the role locally on `ubuntuBlue` with the `localhost` inventory
2. `Phase 2`: create a dedicated `controlOps` VM on Proxmox and verify Ansible SSH connectivity to managed VMs
3. `Phase 3`: move scoring and dashboard services onto the Control VM and expand to additional targets

This order keeps the first proof small. It avoids mixing Linux-bundle issues, SSH issues, and Control-VM build issues in the same test.

## Repo layout

```text
hafb-range-control/
├── README.md
├── Makefile
├── ansible.cfg
├── docs/
│   ├── architecture.md
│   ├── control-vm-rollout.md
│   ├── demo-runbook.md
│   ├── mvp.md
│   └── proxmox-testing.md
├── inventories/
│   ├── localhost.yml
│   ├── proxmox-lab.example.yml
│   └── ubuntuBlue.example.yml
├── playbooks/
│   ├── check_connectivity.yml
│   ├── deploy_sbom_module1.yml
│   └── validate_sbom_module1.yml
├── reports/
│   └── .gitkeep
├── roles/
│   └── sbom_module1/
│       ├── defaults/main.yml
│       └── tasks/
│           ├── deploy.yml
│           ├── main.yml
│           └── validate.yml
├── scoring/
│   ├── score_module1.py
│   └── weights.json
└── scripts/
    ├── deploy.sh
    ├── ping_targets.sh
    ├── score.sh
    └── validate.sh
```

## What Ansible is doing

The Ansible side is deliberately basic:

1. find the extracted Module 1 offline bundle
2. copy that bundle to a staging directory on the target
3. run `install-module1-offline.sh`
4. run `validate-module1-offline.sh`

This is enough to demonstrate end-to-end infrastructure automation for one training module without rebuilding the module logic itself.

## What the current scoring script is doing

The scoring path is also intentionally simple. It awards points for the checks that matter to the MVP:

- bundle source exists
- installed lab directory exists
- required student artifacts exist
- instructor materials exist
- `syft` is on `PATH`
- `jq` is on `PATH`
- `~/labs/sbom-xray` compatibility symlink exists
- the official Module 1 validator passes

This is a readiness score, not the final cyber-range dashboard. It is there to show the pattern of centralized evaluation after automation.

The output is written to:

- [module1-score-latest.json](/Users/taylorpreslar/capstone/hafb-range-control/reports/module1-score-latest.json)
- [module1-score-latest.md](/Users/taylorpreslar/capstone/hafb-range-control/reports/module1-score-latest.md)

## Defaults

By default, the repo expects the extracted bundle to exist at the sibling repo path:

`/Users/taylorpreslar/capstone/SBOM-Training-Module/deploy/releases/Module1-offline-bundle-sbom-xray-2026-03-25_004519`

Override that path with:

```bash
export SBOM_BUNDLE_SOURCE_DIR=/path/to/Module1-offline-bundle-sbom-xray
```

The default target inventory is local:

- [localhost.yml](/Users/taylorpreslar/capstone/hafb-range-control/inventories/localhost.yml)

For the future Control VM model, copy and edit:

- [ubuntuBlue.example.yml](/Users/taylorpreslar/capstone/hafb-range-control/inventories/ubuntuBlue.example.yml)
- [proxmox-lab.example.yml](/Users/taylorpreslar/capstone/hafb-range-control/inventories/proxmox-lab.example.yml)

## Quick start

### Phase 0: local authoring and syntax checks on your Mac

```bash
cd /Users/taylorpreslar/capstone/hafb-range-control

ansible-playbook --syntax-check playbooks/deploy_sbom_module1.yml
ansible-playbook --syntax-check playbooks/validate_sbom_module1.yml

# Optional: local scoring logic only
./scripts/score.sh --skip-validator
```

macOS is not the runtime target for the Module 1 installer. The full deploy and validate flow is expected to fail there by design.

### Phase 1: first real air-gapped test on `ubuntuBlue`

```bash
cd ~/hafb-range-control

export SBOM_BUNDLE_SOURCE_DIR=/tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh -i inventories/localhost.yml
./scripts/validate.sh -i inventories/localhost.yml
./scripts/score.sh
```

That path assumes:

- the repo has been copied to `ubuntuBlue`
- the Module 1 bundle is already staged in `/tmp`
- the test is being run directly on the Linux VM with the default `localhost` inventory

### Phase 2: dedicated Control VM on Proxmox

On the future Control VM, the first thing you should prove is Ansible connectivity to the target VMs:

```bash
cd ~/hafb-range-control
cp inventories/proxmox-lab.example.yml inventories/proxmox-lab.yml
$EDITOR inventories/proxmox-lab.yml

./scripts/ping_targets.sh -i inventories/proxmox-lab.yml
```

Once connectivity works, point deployment at `ubuntuBlue` and run the real module playbooks from the Control VM.

In this architecture, the offline bundle must exist on the Control VM first. The role copies the bundle from the Control VM to the target Linux VM during deployment.
For the current MVP, the readiness score is still easiest to run on `ubuntuBlue` because it checks local files and local tool availability there.

## Demo story

For the capstone, the clean explanation is:

- `SBOM-Training-Module` owns the actual training content and offline installer
- `hafb-range-control` owns automation first, with scoring/dashboard capabilities added incrementally
- we are proving the pattern on one module first
- later, additional modules, vulnerable services, and a Wazuh-backed scoring dashboard can be added to the same control repo

## Validation status

This repo was validated locally for:

- shell script syntax
- Python syntax and scoring script execution

If `ansible-playbook` is installed on the machine, you can run:

```bash
ansible-playbook --syntax-check playbooks/deploy_sbom_module1.yml
ansible-playbook --syntax-check playbooks/validate_sbom_module1.yml
```

## Supporting docs

- [architecture.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/architecture.md)
- [control-vm-rollout.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/control-vm-rollout.md)
- [demo-runbook.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/demo-runbook.md)
- [mvp.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/mvp.md)
- [proxmox-testing.md](/Users/taylorpreslar/capstone/hafb-range-control/docs/proxmox-testing.md)
