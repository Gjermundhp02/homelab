locals {
  domains = ["radarr", "sonarr", "prowlarr", "transmission", "jellyfin", "jellyseerr", "immich"]
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

# k3s ingress records (k3s-test, authentik, ...) are no longer managed here —
# ExternalDNS (cluster/external-dns) owns them from Ingress hosts/annotations.
# Run `terraform state rm` for k3s_test/authentik if they're still in state
# from before this switch, so Terraform doesn't fight ExternalDNS over them.