terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.69"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true # set false if PVE has a valid TLS cert

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
    node {
      name    = var.proxmox_node
      address = var.proxmox_ssh_host
      port    = var.proxmox_ssh_port
    }
  }
}
