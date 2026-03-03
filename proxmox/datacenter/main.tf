// Network configuration for SDN
resource "proxmox_virtual_environment_sdn_zone_simple" "simple1" {
  id    = "simple1"
  nodes = ["gjermuhp"]

  ipam = "pve"
  dhcp = "dnsmasq"
  depends_on = [ proxmox_virtual_environment_sdn_applier.finalizer ]
}

resource "proxmox_virtual_environment_sdn_vnet" "k8s" {
  id = "k8s"
  zone = proxmox_virtual_environment_sdn_zone_simple.simple1.id
  alias = "Kubernetes SDN"
  depends_on = [ proxmox_virtual_environment_sdn_applier.finalizer ]
}

resource "proxmox_virtual_environment_sdn_subnet" "k8s_subnet" {
  vnet = proxmox_virtual_environment_sdn_vnet.k8s.id
  cidr    = "10.0.0.0/24"
  snat = true
  gateway = "10.0.0.1"
  dhcp_range = {
    start_address = "10.0.0.3"
    end_address = "10.0.0.100"
  }
  depends_on = [ proxmox_virtual_environment_sdn_applier.finalizer ]
}

resource "proxmox_virtual_environment_sdn_applier" "vnet_applier" {
  depends_on = [
    proxmox_virtual_environment_sdn_zone_simple.simple1,
    proxmox_virtual_environment_sdn_vnet.k8s,
    proxmox_virtual_environment_sdn_subnet.k8s_subnet
  ]
}

resource "proxmox_virtual_environment_sdn_applier" "finalizer" {
}

// VM configuration
resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "gjermuhp"
  url = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.12.4/nocloud-amd64.iso"
  file_name = "talos-k8s-v1.12.4.iso"
}

module "talos_manager" {
  count = 3
  source = "./vm"
  network_bridge = proxmox_virtual_environment_sdn_vnet.k8s.id
  disk_import_id = proxmox_virtual_environment_download_file.talos_iso.id
}

module "talos_worker" {
  count = 3
  source = "./vm"
  network_bridge = proxmox_virtual_environment_sdn_vnet.k8s.id
  disk_import_id = proxmox_virtual_environment_download_file.talos_iso.id
}

output "manager_ips" {
  value = [for i in range(3) : module.talos_manager[i].k8s_vm_ip]
}

output "worker_ips" {
  value = [for i in range(3) : module.talos_worker[i].k8s_vm_ip]
}