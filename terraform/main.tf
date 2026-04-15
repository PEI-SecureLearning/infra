resource "proxmox_virtual_environment_vm" "runner" {
  name      = var.vm_name
  node_name = var.proxmox_node

  clone {
    vm_id = var.proxmox_template_vm_id
    full  = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = var.proxmox_datastore
    interface    = "scsi0"
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge = var.proxmox_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.vm_ip_cidr
        gateway = var.vm_gateway
      }
    }

    user_account {
      username = "debian"
      keys     = [var.vm_ssh_public_key]
    }
  }

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys,
    ]
  }
}
