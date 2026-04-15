variable "proxmox_endpoint" {
  description = "Proxmox VE API URL (e.g. https://pve.local:8006)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g. terraform@pve!mytoken)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret UUID"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name to deploy the VM on"
  type        = string
}

variable "proxmox_datastore" {
  description = "Proxmox storage pool for VM disk (e.g. local-lvm)"
  type        = string
}

variable "proxmox_bridge" {
  description = "Network bridge for the VM NIC (e.g. vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "proxmox_template_vm_id" {
  description = "VM ID of the Debian 12 cloud-init template to clone"
  type        = number
}

variable "vm_name" {
  description = "Name for the new VM"
  type        = string
  default     = "gh-runner"
}

variable "vm_ip_cidr" {
  description = "Static IP address with prefix length (e.g. 192.168.1.50/24)"
  type        = string
}

variable "vm_gateway" {
  description = "Default gateway for the VM"
  type        = string
}

variable "vm_ssh_public_key" {
  description = "SSH public key injected via cloud-init"
  type        = string
}
