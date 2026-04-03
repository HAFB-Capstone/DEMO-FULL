# Extending The Repository

This document explains how `hafb-range-control` can be expanded beyond the current `sbom_module1` example.

## Purpose

The repository is designed to be a reusable Ansible control plane, not a one-off automation script for a single lab.

The current implementation proves the pattern with one training module, but the same layout can support:

- additional training modules
- vulnerable services
- host configuration tasks
- tool deployment to managed systems

## Core pattern

Every new automation target should follow the same basic structure:

1. inventory identifies the target host or host group
2. playbook selects the role and execution mode
3. role performs deployment tasks
4. role performs validation tasks

The current `sbom_module1` role already follows this pattern.

## Adding another training module

A new training-module role would usually:

1. define a bundle source or artifact path
2. copy or stage the module artifacts on the target
3. run the module installer
4. run the module validator
5. write validation evidence to the target system

Typical file structure:

```text
roles/
  module2_lab/
    defaults/main.yml
    tasks/main.yml
    tasks/deploy.yml
    tasks/validate.yml

playbooks/
  deploy_module2_lab.yml
  validate_module2_lab.yml
```

## Adding a vulnerable service

A vulnerable-service role would usually:

1. target a host such as `ubuntuVictim`
2. copy application code, configuration, or a container stack
3. install required dependencies from approved internal sources
4. start the service
5. validate that the service is reachable or configured correctly

Validation examples:

- `systemctl status <service>`
- `docker compose ps`
- an HTTP health check
- a port check with `ss` or `nc`
- confirmation that a seeded file, database, or config exists

Typical file structure:

```text
roles/
  vulnerable_webapp/
    defaults/main.yml
    tasks/main.yml
    tasks/deploy.yml
    tasks/validate.yml

playbooks/
  deploy_vulnerable_webapp.yml
  validate_vulnerable_webapp.yml
```

## Adding host configuration tasks

Not every role has to be a full application or lab module.

This repo can also manage:

- tool installation
- service enablement
- configuration file placement
- user or directory setup
- lab-specific system preparation

For those roles, deployment may be the main focus, while validation confirms the final system state.

## Recommended standards for new roles

Keep each new role consistent with the existing pattern:

- use `defaults/main.yml` for role-specific variables
- keep deploy and validate tasks separate
- make validation explicit instead of relying on assumptions
- write role-specific evidence files or logs when useful
- avoid mixing unrelated automation targets into one role

## Inventory design

As the repository grows, use inventories to separate host purpose clearly.

Examples:

- `analysis`: training modules and blue-team tooling
- `victim`: vulnerable applications or services
- `red`: red-team workstations or support tooling
- service-specific groups when a workload needs tighter targeting

## Naming guidance

Use clear names that describe the target being automated.

Good examples:

- `module2_lab`
- `vulnerable_webapp`
- `wazuh_agent`
- `blue_tools`

Avoid vague names that hide the role's actual responsibility.

## Practical rule

If a new capability needs its own deployment steps, validation steps, variables, or target hosts, it should usually be its own role and its own pair of playbooks.

That keeps the repository readable and makes it easier to demo, test, and maintain.
