resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "cp" {
  cluster_name     = "talos-k8s"
  machine_type     = "controlplane"
  cluster_endpoint = "https://10.0.0.2:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "cp" {
  for_each = local.manager_ips
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  endpoint                    = each.value
  node                        = each.key
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.cp]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.manager_ips["talos-manager-0"]
  endpoint             = local.manager_ips["talos-manager-0"]
}