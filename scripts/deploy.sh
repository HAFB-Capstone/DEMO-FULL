#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANSIBLE_HOME="${ANSIBLE_HOME:-$ROOT_DIR/.ansible}"
export ANSIBLE_LOCAL_TEMP="${ANSIBLE_LOCAL_TEMP:-$ROOT_DIR/.ansible/tmp}"
export ANSIBLE_REMOTE_TEMP="${ANSIBLE_REMOTE_TEMP:-/tmp/hafb-range-control-ansible}"
mkdir -p "$ANSIBLE_LOCAL_TEMP"
SCRIPT_NAME="$(basename "$0")"

require_explicit_inventory() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -i|--inventory|--inventory-file|--inventory=*|--inventory-file=*)
        return 0
        ;;
    esac
  done

  if [[ "${HAFB_ALLOW_LOCALHOST_INVENTORY:-0}" == "1" ]]; then
    return 0
  fi

  cat >&2 <<EOF
Refusing to run without an explicit Ansible inventory.
This repo defaults to inventories/localhost.yml, which can accidentally deploy Module 1 on the controller.
Use:
  ./scripts/$SCRIPT_NAME -i inventories/proxmox-lab.yml --limit ubuntuBlue
For an intentional localhost run, use:
  ./scripts/$SCRIPT_NAME -i inventories/localhost.yml
To bypass this guard temporarily, set:
  HAFB_ALLOW_LOCALHOST_INVENTORY=1 ./scripts/$SCRIPT_NAME
EOF
  exit 2
}

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook is not installed. Install Ansible first." >&2
  exit 1
fi

require_explicit_inventory "$@"

cd "$ROOT_DIR"
ansible-playbook playbooks/deploy_sbom_module1.yml "$@"
