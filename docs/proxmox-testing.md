# Proxmox Testing

## Environment assumptions

Based on the current lab state:

- Proxmox host: `pve7820`
- Visible VMs: `kaliRed`, `bastion`, `ubuntuVictim`, `ubuntuBlue`
- `ubuntuBlue` appears to be the Linux analysis / blue-team VM
- Wazuh appears to be installed on `ubuntuBlue`
- Module bundles appear to already be staged on `ubuntuBlue` under `/tmp`

For the first deployment test, treat `ubuntuBlue` as both:

- the Ansible execution node
- the module install target

That is the simplest air-gapped proof.

## Recommended first test strategy

Do not start with remote SSH orchestration from your Mac. Start with the lowest-complexity path:

1. log into `ubuntuBlue`
2. run `hafb-range-control` on that VM
3. use the default `localhost` inventory
4. point the control repo at the already-staged Module 1 bundle in `/tmp`

This proves the Ansible pattern before you add any extra SSH, bastion, or remote inventory complexity.

## Recommended second test strategy

After the localhost proof on `ubuntuBlue`, move to the actual architecture:

1. create a dedicated Control VM on Proxmox
2. install Ansible and copy `hafb-range-control` to that VM
3. use the Control VM to reach `ubuntuBlue` over SSH
4. test Ansible connectivity
5. run Module 1 deployment from the Control VM to `ubuntuBlue`

## Step 1: verify `ubuntuBlue` state

On `ubuntuBlue`, run:

```bash
hostname
uname -a
pwd
ls -lah /tmp
ls -lah /tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519
systemctl status wazuh-indexer --no-pager
systemctl status wazuh-manager --no-pager
systemctl status wazuh-dashboard --no-pager
docker ps -a
ss -tulpn
```

What you are looking for:

- the Module 1 bundle exists in `/tmp`
- `ubuntuBlue` is a Linux machine and usable as the analysis VM
- Wazuh presence is confirmed, even if not all services are healthy

## Step 2: place the control repo on `ubuntuBlue`

You need `hafb-range-control` available on the VM. Do this however your air-gapped process allows:

- `scp`
- removable media
- shared datastore
- internal Git mirror

Once copied:

```bash
cd ~/hafb-range-control
ls -lah
```

## Step 3: verify Ansible is installed on `ubuntuBlue`

```bash
ansible-playbook --version
```

If it is not installed, install it using your approved internal package source. Do not rely on public internet installs in the actual air-gapped workflow.

## Step 4: point the control repo at the local Module 1 bundle

```bash
export SBOM_BUNDLE_SOURCE_DIR=/tmp/Module1-offline-bundle-sbom-xray-2026-03-25_004519
```

Check that the bundle is visible:

```bash
ls -lah "$SBOM_BUNDLE_SOURCE_DIR"
```

## Step 5: run an Ansible syntax check

From inside the repo:

```bash
ansible-playbook --syntax-check playbooks/deploy_sbom_module1.yml
ansible-playbook --syntax-check playbooks/validate_sbom_module1.yml
```

This proves the playbooks parse correctly on the VM before you attempt the real deploy.

## Step 6: run the actual deploy

Because you are on `ubuntuBlue`, use the `localhost` inventory explicitly:

```bash
./scripts/deploy.sh -i inventories/localhost.yml
```

What this should do:

- read the Module 1 bundle from `/tmp`
- copy it into the repo-defined staging path
- normalize the student file naming mismatch
- run `install-module1-offline.sh`
- create the install stamp file

## Step 7: validate the install

```bash
./scripts/validate.sh -i inventories/localhost.yml
```

What this should do:

- run the module's own offline validator
- confirm the lab directory exists
- confirm required files are present
- confirm `syft` and `jq` are usable

## Step 8: review validation evidence

```bash
cat ~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt
cat ~/labs/sbom-Module1-sbom-xray/.hafb_range_control_installed
```

What you want to see:

- validation output showing the official validator passed
- install metadata showing the bundle source and lab path used by automation

## Step 9: manually verify the installed module

Check that the lab exists where expected:

```bash
ls -lah ~/labs
ls -lah ~/labs/sbom-Module1-sbom-xray
ls -lah ~/labs/sbom-xray
which syft
which jq
```

Optional spot checks:

```bash
cd ~/labs/sbom-xray
syft flight-path-v1.tar -o cyclonedx-json | jq '.components | length'
syft radar-control-v1.tar -o cyclonedx-json | jq '.components | length'
```

## Step 10: capture evidence for capstone/demo

Save or screenshot:

- `ansible-playbook --version`
- successful `./scripts/deploy.sh`
- successful `./scripts/validate.sh`
- `~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt`
- `ls -lah ~/labs/sbom-xray`

That gives you a clean story:

- one control repo
- one Ansible role
- one deployed module
- one validation path

## After this first proof

Only after the `ubuntuBlue` localhost flow works cleanly should you add:

- the dedicated Control VM
- remote inventories
- bastion-based SSH routing if needed
- more modules
- any external scoring or dashboard integration
