locals {
  domains = ["radarr", "sonarr", "prowlarr", "transmission", "jellyfin", "jellyseerr"]
}

data "cloudflare_zone" "example_zone" {
  filter = {
    name = "hpedersen.no"
  }
}

resource "cloudflare_dns_record" "example_dns_record" {
  for_each = toset(local.domains)
  name = each.key
  type = "A"
  content = "100.80.140.92"
  ttl = 300
  zone_id = data.cloudflare_zone.example_zone.id
}