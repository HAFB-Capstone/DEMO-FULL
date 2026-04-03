# Control VM Rollout

## Goal

Create a dedicated Linux VM on Proxmox whose only job is:

- host `hafb-range-control`
- run Ansible

This VM becomes the automation control node for the lab.

## Recommended VM role

Use a small Ubuntu Server VM for the first version of the Control VM.

Recommended baseline:

- 2 vCPU
- 4 GB RAM
- 32 GB disk
- one NIC on the internal lab network
- static IP or reserved DHCP lease
- OpenSSH enabled

## Step-by-step Proxmox implementation

### 1. Create the VM

In Proxmox:

1. click `Create VM`
2. name it something like `controlOps` or `hafb-control`
3. select the Ubuntu Server ISO already approved for the lab
4. assign disk, CPU, memory, and network
5. finish the wizard and start the VM

### 2. Install the base OS

During install:

- create a normal admin user
- enable OpenSSH server
- put the VM on the same internal network as `ubuntuBlue`
- avoid any configuration that assumes internet access after deployment

### 3. Verify network reachability

From the Control VM:

```bash
hostname
ip a
ping -c 3 ubuntuBlue
```

If DNS does not resolve hostnames, use IP addresses instead.

If the lab requires a jump path, route SSH through `bastion`. If the Control VM sits on the same internal network as `ubuntuBlue`, keep the first test direct and avoid bastion complexity.

### 4. Install required tools

Install these from your approved internal package source:

- `git`
- `ansible`
- `openssh-client`
- `python3`

Then verify:

```bash
ansible-playbook --version
python3 --version
git --version
ssh -V
```

### 5. Copy the control repo to the Control VM

However your air-gapped workflow supports it:

- internal Git mirror
- scp
- removable media
- datastore copy

Then:

```bash
cd ~
ls -lah
cd ~/hafb-range-control
```

### 6. Create a real inventory

Edit:

- Control VM hostname/IP
- `ubuntuBlue` hostname/IP
- `ubuntuVictim` hostname/IP
- `kaliRed` hostname/IP
- SSH user for each target

The current `inventories/proxmox-lab.yml` already includes:

- `ubuntuBlue` at `192.168.86.37` with user `hafb`
- `ubuntuVictim` at `192.168.86.32` with user `hafb`
- `kaliRed` at `192.168.86.27` with user `kali`

Keep the Kali password out of version control. Use SSH keys or `-k` / `--ask-pass` when you need password authentication.

### 7. Set up SSH trust from Control VM to target VM

On the Control VM:

```bash
ssh-keygen -t ed25519
ssh-copy-id student@ubuntuBlue
```

If `ssh-copy-id` is unavailable, append the public key manually to `~/.ssh/authorized_keys` on `ubuntuBlue`.

Then test:

```bash
ssh student@ubuntuBlue hostname
```

If direct SSH is not allowed and `bastion` must be used, add `ansible_ssh_common_args` in the inventory later. Do not introduce that until direct SSH has been ruled out.

### 8. Test Ansible connectivity

Run:

```bash
./scripts/ping_targets.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

What success looks like:

- Ansible can connect to `ubuntuBlue`
- the ping module returns success
- host facts can be gathered

### 9. Stage the Module 1 bundle on the Control VM

On the Control VM:

```bash
mkdir -p ~/bundles
cp -R /path/from/internal-media/Module1-offline-bundle-sbom-xray-2026-03-25_004519 ~/bundles/
export SBOM_BUNDLE_SOURCE_DIR=~/bundles/Module1-offline-bundle-sbom-xray-2026-03-25_004519
```

Important: `sbom_bundle_source_dir` is read on the Ansible controller. In the Control-VM architecture, that means the offline bundle must exist on the Control VM first. The playbook then copies the bundle from the Control VM to `ubuntuBlue`.

### 10. Run the real deploy from the Control VM

```bash
./scripts/deploy.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
./scripts/validate.sh -i inventories/proxmox-lab.yml --limit ubuntuBlue
```

Important:

- `deploy.sh` and `validate.sh` require an explicit `-i` inventory argument
- this is intentional so the wrapper does not fall back to `inventories/localhost.yml` and accidentally act on the controller
- `SBOM_BUNDLE_SOURCE_DIR` is read on `controlOps`, not on `ubuntuBlue`

What success looks like:

- deploy stages the bundle on `ubuntuBlue` and runs the offline installer there
- validate runs the Module 1 validator on `ubuntuBlue`
- validation output shows the pinned tool versions and expected component-count band
- current known-good output includes:
  - `syft 1.23.1`
  - `jq-1.7`
  - `flight-path components: 3362`
  - `radar-control components: 3351`

### 11. Review validation evidence

Once validation succeeds, review the evidence written by the automation on `ubuntuBlue`:

```bash
ssh student@ubuntuBlue 'cat ~/labs/sbom-Module1-sbom-xray/.hafb_range_control_last_validate.txt'
ssh student@ubuntuBlue 'cat ~/labs/sbom-Module1-sbom-xray/.hafb_range_control_installed'
```

### 12. Reset strategy for milestone 1

For the first milestone, prefer a Proxmox snapshot-based reset over trying to perfectly reverse every file change made by the installer.

Recommended approach:

1. create a snapshot of `ubuntuBlue` before the first deploy test
2. use Ansible deploy and validate from `controlOps`
3. if you need a clean retry, roll `ubuntuBlue` back to that snapshot

This keeps the first milestone safe and repeatable while the automation path is still being proven.

## What to prove in testing

For the first Control VM milestone, prove these things only:

- the Control VM can reach `ubuntuBlue`
- Ansible can run from the Control VM
- Module 1 can be deployed to `ubuntuBlue`
- Module 1 can be validated

That is enough for the first serious proof-of-concept.

## What comes after

Once the Control VM path works:

- add a second module or service
- add `ubuntuVictim` to inventory
- integrate with external scoring or visibility tooling if needed
