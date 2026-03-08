terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.91.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.10.1"
    }
  }
  backend "s3" {
    bucket = "homelabtfstate"
    key    = "terraform.tfstate"
    region = "de"
    # sbg or any activated high performance storage region
    endpoints = {
      s3 = "https://s3.de.io.cloud.ovh.net/"
    }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "proxmox" {
  insecure = true
  ssh {
    agent = true
    username = "root"
  }
}