# infra

Infrastructure as code for the PEI-SecureLearning organization. Provisions a Proxmox VM and configures it as a GitHub Actions org-level self-hosted runner with Docker support.

## Stack

- **Terraform** — VM provisioning on Proxmox via [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest)
- **Ansible** — VM configuration: GitHub Actions runner + Docker engine
- **GitHub Actions** — orchestrates the full deploy pipeline

## What gets deployed

- Proxmox VM: 2 vCPU, 4 GB RAM, 20 GB disk, Debian 12 cloud-init clone
- Docker CE + Docker Compose plugin + Docker Buildx plugin
- GitHub Actions org-level runner registered to `PEI-SecureLearning`

## Prerequisites

1. A Debian 12 cloud-init template VM exists on the Proxmox node (with `qemu-guest-agent` installed)
2. A Proxmox API token with VM provisioning permissions
3. An SSH key pair — public key goes into cloud-init, private key used by Ansible
4. A GitHub PAT with `admin:org` scope for runner registration
5. A `production` environment created in this repository (Settings → Environments)

## Repository setup

After creating the `production` environment, configure the following in **Settings → Environments → production**.

### Variables (non-sensitive)

| Name | Example | Description |
|---|---|---|
| `PROXMOX_ENDPOINT` | `https://pve.local:8006` | Proxmox VE API URL |
| `PROXMOX_NODE` | `pve` | Proxmox node name |
| `PROXMOX_DATASTORE` | `local-lvm` | Storage pool for VM disk |
| `PROXMOX_BRIDGE` | `vmbr0` | Network bridge for VM NIC |
| `PROXMOX_TEMPLATE_VM_ID` | `9000` | VM ID of the Debian 12 cloud-init template |
| `VM_NAME` | `gh-runner` | Name assigned to the new VM |
| `VM_IP_CIDR` | `192.168.1.50/24` | Static IP with prefix length |
| `VM_GATEWAY` | `192.168.1.1` | Default gateway |

### Secrets (sensitive)

| Name | Description |
|---|---|
| `PROXMOX_API_TOKEN_ID` | Proxmox API token ID (e.g. `terraform@pve!mytoken`) |
| `PROXMOX_API_TOKEN_SECRET` | Proxmox API token secret UUID |
| `VM_SSH_PUBLIC_KEY` | SSH public key injected via cloud-init |
| `VM_SSH_PRIVATE_KEY` | SSH private key used by Ansible to connect to the VM |
| `GH_TOKEN` | GitHub PAT with `admin:org` scope |

## Running the deploy

The workflow triggers automatically on push to `main` when files under `terraform/` or `ansible/` change. To trigger manually:

```
Actions → Deploy GitHub Runner → Run workflow
```

The org name is derived automatically from `github.repository_owner` — no manual input needed.

## Terraform state

State is stored locally by default. For team use, configure a remote backend (S3-compatible, Terraform Cloud, etc.) in `terraform/versions.tf`.

## Project structure

```
.
├── terraform/
│   ├── versions.tf      # Provider and Terraform version constraints
│   ├── variables.tf     # All input variables
│   ├── main.tf          # VM resource definition
│   └── outputs.tf       # VM IP and ID outputs
├── ansible/
│   ├── playbooks/
│   │   └── github-runner.yml
│   └── roles/
│       └── github-runner/
│           ├── tasks/main.yml
│           └── defaults/main.yml
└── .github/
    └── workflows/
        └── deploy.yml
```
