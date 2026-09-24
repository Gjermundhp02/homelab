{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./microvm.nix
    ../crowdsec-bouncer.nix  # enable after: cscli bouncers add crowdsec-firewall-bouncer → add key to secrets/secrets.yaml
    (import ../monitoring-agent.nix {lokiUrl = "http://192.168.101.1:3100/loki/api/v1/push";})
    ../file-transfer-monitoring.nix
  ];

  networking.firewall.interfaces.microbr0.allowedTCPPorts = [9100 6060 10250];
  networking.firewall.interfaces.microbr0.allowedUDPPorts = [8472];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/id_ed25519"];
  sops.secrets.k3s_token = {};
  sops.secrets.tailscale_key = {};
  sops.secrets.ssh = {
    owner = "gjermund";
    mode = "0400";
    path = "/home/gjermund/.ssh/id_ed25519";
  };

  # Sole k3s workload node: runs Traefik + its ServiceLB, which binds host
  # ports 80/443 here (nas is tainted control-plane-only, so nothing on nas
  # ever competes with this — see nas/configuration.nix).
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.101.1:6443";
    tokenFile = config.sops.secrets.k3s_token.path;
    extraFlags = toString [
      "--node-ip=192.168.101.2"
      "--flannel-iface=microbr0"
    ];
  };

  # Independent Tailscale identity so the public ingress path (Cloudflare
  # DNS -> this host's tailscale IP -> Traefik) never depends on nas/Caddy.
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_key.path;
  };

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # Stage-1 initrd unlock from physical USB.
  # keyFile points at a raw partition on the stick (no filesystem) holding
  # random key bytes enrolled as a LUKS key slot on each device.
  boot.initrd = {
    kernelModules = [ "uas" "usb_storage" "vfat" ];

    luks.devices = {
      "crypted-root" = {
        allowDiscards = true;
        keyFile = "/dev/disk/by-id/usb-VendorCo_ProductCode_1264371230950464243-0:0-part2";
        keyFileSize = 4096;
        fallbackToPassword = true;
      };
      "crypted-raid" = {
        allowDiscards = true;
        keyFile = "/dev/disk/by-id/usb-VendorCo_ProductCode_1264371230950464243-0:0-part2";
        keyFileSize = 4096;
        fallbackToPassword = true;
      };
    };
  };

  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  # From generated configuration.nix
  networking.useNetworkd = true;
  systemd.network.enable = true;

  users.users.gjermund = {
    createHome = true;
    hashedPassword = "$y$j9T$alon146pbcXNU.dnNeLbe1$BfAEeXwy6ms/B5Z7CeDePw6Z7lfjF0Sxpu676yM1vi3";
  };
}
