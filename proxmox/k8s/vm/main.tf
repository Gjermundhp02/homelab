variable "name" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "disk_import_id" {
  type = string
}

resource "proxmox_virtual_environment_vm" "k8s_vm" {
  name        = var.name
  description = "Managed by Terraform"
  tags        = ["terraform", "k8s"]

  node_name = "gjermuhp"

  agent {
    enabled = true
    wait_for_ip {
      ipv4 = true
    }
  }
  started = true

  cpu {
    cores        = 4
    type         = "x86-64-v2-AES"  # recommended for modern CPUs
  }

  memory {
    dedicated = 4096
    floating  = 4096 # set equal to dedicated to enable ballooning
  }

  disk {
    datastore_id = "local-lvm"
    size = 10
    file_format = "raw"
    interface    = "scsi0"
    cache = "writethrough"
  }

  cdrom {
    file_id = var.disk_import_id
  }

  network_device {
    bridge = var.network_bridge
  }
}

output "k8s_vm_ip" {
  value = proxmox_virtual_environment_vm.k8s_vm.ipv4_addresses
}

output "name" {
  value = var.name
}