#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANSIBLE_HOME="${ANSIBLE_HOME:-$ROOT_DIR/.ansible}"
export ANSIBLE_LOCAL_TEMP="${ANSIBLE_LOCAL_TEMP:-$ROOT_DIR/.ansible/tmp}"
export ANSIBLE_REMOTE_TEMP="${ANSIBLE_REMOTE_TEMP:-/tmp/hafb-range-control-ansible}"
mkdir -p "$ANSIBLE_LOCAL_TEMP"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook is not installed. Install Ansible first." >&2
  exit 1
fi

cd "$ROOT_DIR"
ansible-playbook playbooks/check_connectivity.yml "$@"
