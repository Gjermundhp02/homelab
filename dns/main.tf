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

# k3s ingress test service (traefik/whoami on compute), reachable only via
# compute's own Tailscale identity — deliberately independent of nas/Caddy.
# TODO: replace with compute's actual `tailscale ip -4` once it has joined the tailnet.
resource "cloudflare_dns_record" "k3s_test" {
  name    = "k3s-test"
  type    = "A"
  content = "100.117.83.4" # placeholder — update after compute joins Tailscale
  ttl     = 300
  zone_id = data.cloudflare_zone.example_zone.id
}