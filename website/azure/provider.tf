terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.56.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.14.0"
    }
  }

  backend "azurerm" {
    storage_account_name = "website2x23c"
    container_name       = "tfstate"
    key                  = "azure.terraform.tfstate"
    resource_group_name  = "homelab"
  }
}

provider "azurerm" {
  features {

  }
}