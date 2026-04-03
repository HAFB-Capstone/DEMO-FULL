# Demo Runbook

## Goal

Demonstrate that one central repo can:

1. deploy one training module with Ansible
2. validate it
3. score its readiness

This runbook is for the current MVP, which is automation-first.

## Target note

Run the actual deploy and validate playbooks on `ubuntuBlue` or another Linux analysis VM. The Module 1 bundle includes Linux tooling and will not execute end to end on macOS.

The Control VM architecture is the next stage. This runbook keeps the first proof smaller by validating the role directly on a Linux target before introducing remote orchestration.

## Recommended MVP demo commands

```bash
cd ~/hafb-range-control

export SBOM_BUNDLE_SOURCE_DIR=/tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519

./scripts/deploy.sh
./scripts/validate.sh
./scripts/score.sh
```

## What to say

- This repo is the automation control-plane MVP.
- We are proving the pattern on one module, not the whole range.
- The first objective is automation with Ansible.
- The second objective, a Wazuh-backed scoring dashboard, comes later.
- Ansible deploys the SBOM Module 1 offline bundle using the module's own installer.
- Validation proves the install worked.
- Scoring turns that validation state into a simple readiness score.

## What success looks like

- Ansible reports the deploy completed.
- Ansible validation passes.
- The score report lands in `reports/` and shows a high or perfect readiness score.

## After the MVP

Once this works on `ubuntuBlue`, the next logical extension is:

1. create a dedicated Control VM on Proxmox
2. run `hafb-range-control` from that VM
3. verify Ansible connectivity to `ubuntuBlue`, `ubuntuVictim`, and later other targets
4. add a second role for another module or vulnerable service
5. add a small web dashboard
6. ingest Wazuh alert data and service-health checks into that dashboard
