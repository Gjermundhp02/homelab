{config, host, ...}: {
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/id_ed25519"];
  sops.secrets.tailscale_key = {};

  nixarr = {
    enable = true;
    # These two values are also the default, but you can set them to whatever
    # else you want
    # WARNING: Do _not_ set them to `/home/user/whatever`, it will not work!
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = true;
      # WARNING: This file must _not_ be in the config git directory
      # You can usually get this wireguard file from your VPN provider
      wgConf = config.sops.secrets.protonvpn.path;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = 51820;
    };

    # It is possible for this module to run the *Arrs through a VPN, but it
    # is generally not recommended, as it can cause rate-limiting issues.
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr = {
      enable = true;
      openFirewall = true;
    };
    radarr = {
      enable = true;
      openFirewall = true;
    };
    sonarr = {
      enable = true;
      openFirewall = true;
    };
    seerr = {
      enable = true;
      openFirewall = true;
    };
  };
  services.transmission.settings = {
    rpc-host-whitelist = "nas.tail7cc95a.ts.net,localhost,127.0.0.1";
  };

  services.flaresolverr.enable = true;

  services.tailscale = {
    enable = true;
    permitCertUid = "caddy";

    authKeyFile = config.sops.secrets.tailscale_key.path;
  };

  networking.nftables.enable = true;

  # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  # 3. Optimization: Prevent systemd from waiting for network online
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  services.caddy = {
    enable = true;
    virtualHosts."${host}.tail7cc95a.ts.net".extraConfig = builtins.readFile ./Caddyfile;
  };
}
