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
locals {
  talos_version = "v1.12.4"
}

data "talos_image_factory_extensions_versions" "talos_extensions" {
  # get the latest talos version
  talos_version = local.talos_version
  filters = {
    names = [
      "qemu-guest-agent"
    ]
  }
}

resource "talos_image_factory_schematic" "talos_schematic" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.talos_extensions.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "talos_url" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.talos_schematic.id
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "gjermuhp"
  url = data.talos_image_factory_urls.talos_url.urls.iso
  file_name = "talos-k8s-v1.12.4.iso"
}

module "talos_manager" {
  count = 3
  name = "talos-manager-${count.index}"
  source = "./vm"
  network_bridge = proxmox_virtual_environment_sdn_vnet.k8s.id
  disk_import_id = proxmox_virtual_environment_download_file.talos_iso.id
}

module "talos_worker" {
  count = 3
  name = "talos-worker-${count.index}"
  source = "./vm"
  network_bridge = proxmox_virtual_environment_sdn_vnet.k8s.id
  disk_import_id = proxmox_virtual_environment_download_file.talos_iso.id
}

locals {
  manager_ips = {for vm in range(3) :  "${module.talos_manager[vm].name}" => [for ip in flatten(flatten(module.talos_manager[vm].k8s_vm_ip)) : ip if ip != "127.0.0.1" && ip != "169.254.116.108"][0]}
  worker_ips =  {for vm in range(3) : "${module.talos_worker[vm].name}" => [for ip in flatten(flatten(module.talos_worker[vm].k8s_vm_ip)) : ip if ip != "127.0.0.1" && ip != "169.254.116.108"][0]}
}

output "manager_ips" {
  value = local.manager_ips
}

output "worker_ips" {
  value = local.worker_ips
}
