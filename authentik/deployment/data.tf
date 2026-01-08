data "azurerm_resource_group" "homelab-rg" {
  name = "homelab"
}

data "azurerm_storage_account" "authentik" {
  resource_group_name = data.azurerm_resource_group.homelab-rg.name
  name                = "authentik2026"
}

data "azurerm_client_config" "current" {}

data "cloudflare_zone" "hpedersen" {
  filter = {  
    name = "hpedersen.no"
  }
}

# Reference the existing Container App Environment from the website deployment
data "azurerm_container_app_environment" "website_env" {
  name                = "website-environment"
  resource_group_name = data.azurerm_resource_group.homelab-rg.name
}