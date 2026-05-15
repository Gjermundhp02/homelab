{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = ["/id_ed25519"];
  # This is the actual specification of the secrets.
  sops.secrets."wireguard/private_key" = {};
  sops.secrets.protonvpn = {};
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

  services.flaresolverr.enable = true;

  services.tailscale = {
    enable = true;
    
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

  systemd.tmpfiles.settings = {
    "10-mypackage" = {
      d = {
        "/nfs/proxmox" = {
          group = "users";
          user = "nixos";
        };
      };
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /nfs *(rw,sync,no_subtree_check,no_root_squash)
      /nfs/proxmox 192.168.0.0/24(rw,sync,insecure,no_subtree_check,no_root_squash) 10.50.0.2/24(rw,sync,insecure,no_subtree_check,no_root_squash)
    '';
  };

  networking.wireguard.interfaces = {
    wg1 = {
      ips = ["10.50.0.1/24"];
      listenPort = 51820;

      privateKeyFile = config.sops.secrets."wireguard/private_key".path;

      peers = [
        {
          # Proxmox node
          publicKey = "CMY4RuvynPyXhRvSPKAt83HYdLGFarc382pjvUtWGCo=";
          allowedIPs = ["10.50.0.2/32"];
        }
      ];
    };
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [2049 51820 config.services.tailscale.port ];
    allowedTCPPorts = [2049];
  };

  # From generated configuration.nix
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };
  # Configure console keymap
  console.keyMap = "no";
  users.users.gjermund = {
    extraGroups = [ "networkmanager" ];
  };
}
