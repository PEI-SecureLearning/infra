output "vm_id" {
  description = "Proxmox VM ID of the runner"
  value       = proxmox_virtual_environment_vm.runner.vm_id
}

output "vm_ipv4_address" {
  description = "IPv4 address of the runner VM"
  value       = var.vm_ip_cidr != "" ? split("/", var.vm_ip_cidr)[0] : proxmox_virtual_environment_vm.runner.ipv4_addresses[1][0]
}

output "vm_name" {
  description = "Name of the runner VM"
  value       = proxmox_virtual_environment_vm.runner.name
}
