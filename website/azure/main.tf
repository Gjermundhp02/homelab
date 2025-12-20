locals {
  location = "norwayeast"
}

resource "azurerm_log_analytics_workspace" "website_log" {
  name                = "website-log-01"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.homelab-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "website_env" {
  name                       = "website-environment"
  location                   = local.location
  resource_group_name        = data.azurerm_resource_group.homelab-rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.website_log.id
}

resource "azurerm_container_app" "website_app" {
  name                         = "website-app"
  container_app_environment_id = azurerm_container_app_environment.website_env.id
  resource_group_name          = data.azurerm_resource_group.homelab-rg.name
  revision_mode                = "Single"

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-pat"
  }

  secret {
    name  = "ghcr-pat"
    value = var.ghcr_token
  }

  ingress {
    external_enabled = true
    target_port = 3000
    traffic_weight {
      percentage = 100
      revision_suffix = "h9ww1j5"
    }
  }

  template {
    container {
      name   = "website-app"
      image  = "ghcr.io/${var.ghcr_username}/website:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 1
  }
}


resource "azurerm_container_app_custom_domain" "container_domain" {
  name             = "${cloudflare_dns_record.azure-cname.name}"
  container_app_id = azurerm_container_app.website_app.id

  lifecycle {
    // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
  depends_on = [ cloudflare_dns_record.azure-verification ]
}

resource "cloudflare_dns_record" "azure-verification" {
  name = "asuid.azure"
  type = "TXT"
  zone_id = data.cloudflare_zone.hpedersen.id
  content = "\"${azurerm_container_app.website_app.custom_domain_verification_id}\""
  ttl = 300
}

resource "cloudflare_dns_record" "azure-cname" {
  name = "azure"
  type = "CNAME"
  zone_id = data.cloudflare_zone.hpedersen.id
  content = azurerm_container_app.website_app.ingress[0].fqdn
  ttl = 300
}

resource "null_resource" "custom_domain_and_managed_certificate" {
    provisioner "local-exec" {
        command = "az containerapp hostname bind --hostname ${cloudflare_dns_record.azure-cname.name} -g ${data.azurerm_resource_group.homelab-rg.name} -n ${azurerm_container_app.website_app.name} --environment ${azurerm_container_app_environment.website_env.name} --validation-method CNAME"
    }
    triggers = {
        settings = "${azurerm_container_app.website_app.custom_domain_verification_id}-${azurerm_container_app.website_app.ingress[0].fqdn}"
    }
    depends_on = [ azurerm_container_app.website_app, cloudflare_dns_record.azure-verification ]
}
