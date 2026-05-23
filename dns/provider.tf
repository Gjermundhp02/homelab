terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  backend "s3" {
    bucket = "homelabtfstate"
    key    = "arrstack/dns.tfstate"
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

provider "cloudflare" {
}