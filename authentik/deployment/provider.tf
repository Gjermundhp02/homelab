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
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }

  backend "azurerm" {
    storage_account_name = "authentik2026"
    container_name       = "tfstate"
    key                  = "authentik-deployment.terraform.tfstate"
    resource_group_name  = "homelab"
  }
}

provider "azurerm" {
  features {

  }
}