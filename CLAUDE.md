# CLAUDE.md

Context for working in this repo.

## Purpose

Provisions a Proxmox VM and configures it as a GitHub Actions org-level self-hosted runner for the `PEI-SecureLearning` organization. The runner is intended as the production deployment target — Docker and Docker Compose/Buildx are installed on it.

## Stack

- Terraform (`bpg/proxmox` provider ~> 0.69) — VM lifecycle
- Ansible — post-provision configuration (runner + Docker)
- GitHub Actions — orchestration (`environment: production`)

## Key design decisions

- **Proxmox auth**: API token only (not username/password). Format passed to provider: `TOKEN_ID=TOKEN_SECRET`.
- **Org name**: derived from `github.repository_owner` in the workflow — never hardcoded or stored as a variable.
- **Vars vs secrets**: non-sensitive Proxmox and VM config live as GitHub Actions Variables (`vars.*`); credentials live as Secrets (`secrets.*`). Both scoped to the `production` environment.
- **No home dir for runner user**: `github-runner` is a system user with no home directory. Runner files live at `/opt/github-runner`, work dir at `/opt/github-runner/_work`.
- **Docker**: installed from the official Docker apt repo (not Debian's distro packages — too old). `github-runner` user is in the `docker` group so CI jobs run Docker without sudo.
- **Static IP**: VM uses cloud-init static IP (`VM_IP_CIDR` + `VM_GATEWAY`). The output `vm_ipv4_address` strips the prefix from the CIDR rather than relying on the QEMU guest agent to report it.
- **VM template**: Debian 12 cloud-init clone. Template must have `qemu-guest-agent` installed. Cloud-init user is `debian`.

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

- Non-sensitive config (endpoints, node names, IPs): add to `terraform/variables.tf` + expose via `vars.*` in the workflow env block.
- Sensitive values: add to `terraform/variables.tf` with `sensitive = true` + expose via `secrets.*` in the workflow.
- Always update README.md variable tables when adding new inputs.

## Terraform state

Currently local. If remote state is needed, add a `backend` block to `terraform/versions.tf` and configure credentials separately (do not commit backend credentials).

## GitHub environment

The workflow runs under the `production` environment. All variables and secrets must be set there, not at the repository level, to benefit from environment protection rules.

## Common tasks

**Re-run the deploy without code changes:**
Trigger manually from Actions → Deploy GitHub Runner → Run workflow.

**Change VM specs:**
Edit `terraform/main.tf` — `cpu.cores` and `memory.dedicated`. Re-run the workflow; Terraform will update in-place where Proxmox supports it.

**Change runner labels:**
Edit `runner_labels` in `ansible/roles/github-runner/defaults/main.yml`. Re-run the workflow; Ansible will re-configure the runner (`--replace` flag handles re-registration).

**Add more software to the VM:**
Add tasks to `ansible/roles/github-runner/tasks/main.yml`. Keep Docker-related tasks grouped near the top before the runner user is created.
