data "azurerm_resource_group" "homelab-rg" {
  name = "homelab"
}

data "cloudflare_zone" "hpedersen" {
  filter = {  
    name = "hpedersen.no"
  }
}