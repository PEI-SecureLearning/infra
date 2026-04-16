# CLAUDE.md

Context for working in this repo.

## Purpose

Provisions Proxmox VM, configures as GitHub Actions org-level self-hosted runner for `PEI-SecureLearning`. Runner = production deploy target — Docker + Docker Compose/Buildx installed.

## Stack

- Terraform (`bpg/proxmox` provider ~> 0.69) — VM lifecycle
- Ansible — post-provision config (runner + Docker)
- GitHub Actions — orchestration (`environment: production`)

## Key design decisions

- **Proxmox auth**: API token only (not username/password). Format passed to provider: `TOKEN_ID=TOKEN_SECRET`.
- **Org name**: derived from `github.repository_owner` in workflow — never hardcoded or stored as variable.
- **Vars vs secrets**: non-sensitive Proxmox/VM config = GitHub Actions Variables (`vars.*`); credentials = Secrets (`secrets.*`). Both scoped to `production` environment.
- **No home dir for runner user**: `github-runner` = system user, no home dir. Runner files at `/opt/github-runner`, work dir at `/opt/github-runner/_work`.
- **Docker**: installed from official Docker apt repo (not Debian distro packages — too old). `github-runner` user in `docker` group so CI jobs run Docker without sudo.
- **Static IP**: VM uses cloud-init static IP (`VM_IP_CIDR` + `VM_GATEWAY`). Output `vm_ipv4_address` strips prefix from CIDR, not QEMU guest agent.
- **VM template**: Debian 12 cloud-init clone. Template needs `qemu-guest-agent`. Cloud-init user is `debian`.

## File map

| File | Role |
|---|---|
| `terraform/versions.tf` | Provider declaration and auth config |
| `terraform/variables.tf` | All Terraform input variables |
| `terraform/main.tf` | `proxmox_virtual_environment_vm` resource |
| `terraform/outputs.tf` | `vm_ipv4_address`, `vm_id`, `vm_name` |
| `ansible/playbooks/github-runner.yml` | Top-level playbook, targets `runners` group |
| `ansible/roles/github-runner/defaults/main.yml` | Role defaults (`runner_dir`, `runner_user`, labels) |
| `ansible/roles/github-runner/tasks/main.yml` | Docker install → runner download → register → systemd |
| `.github/workflows/deploy.yml` | Terraform apply → SSH wait → Ansible |

## Adding or changing variables

- Non-sensitive config (endpoints, node names, IPs): add to `terraform/variables.tf` + expose via `vars.*` in workflow env block.
- Sensitive values: add to `terraform/variables.tf` with `sensitive = true` + expose via `secrets.*` in workflow.
- Always update README.md variable tables when adding new inputs.

## Terraform state

Currently local. If remote state needed, add `backend` block to `terraform/versions.tf` + configure credentials separately (never commit backend credentials).

## GitHub environment

Workflow runs under `production` environment. All variables + secrets must be set there, not repo level — needed for environment protection rules.

## Common tasks

**Re-run deploy without code changes:**
Trigger manually: Actions → Deploy GitHub Runner → Run workflow.

**Change VM specs:**
Edit `terraform/main.tf` — `cpu.cores` and `memory.dedicated`. Re-run workflow; Terraform updates in-place where Proxmox supports.

**Change runner labels:**
Edit `runner_labels` in `ansible/roles/github-runner/defaults/main.yml`. Re-run workflow; Ansible re-configures runner (`--replace` handles re-registration).

**Add software to VM:**
Add tasks to `ansible/roles/github-runner/tasks/main.yml`. Keep Docker tasks grouped near top before runner user created.