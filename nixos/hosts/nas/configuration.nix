{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../disk-config.nix
    ./arrstack.nix
    ./microvm.nix
    ../crowdsec-bouncer.nix
    ../file-transfer-monitoring.nix
    ./monitoring.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = ["/id_ed25519"];
  # This is the actual specification of the secrets.
  sops.secrets."wireguard/private_key" = {};
  sops.secrets.protonvpn = {};
  sops.secrets.k3s_token = {};
  sops.secrets.ssh = {
    owner = "gjermund";
    mode = "0400";
    path = "/home/gjermund/.ssh/id_ed25519";
  };

  # k3s control-plane only: no workloads (including Traefik's ServiceLB,
  # which would otherwise bind ports 80/443 and clash with Caddy above)
  # are scheduled on this node — see cluster/test-ingress for the worker side.
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets.k3s_token.path;
    extraFlags = toString [
      "--node-ip=192.168.101.1"
      "--flannel-iface=eno1"
      "--node-taint=node-role.kubernetes.io/control-plane:NoSchedule"
      "--write-kubeconfig-mode=644"
      "--tls-san=100.80.140.92" # nas's tailscale IP, for kubectl access over the tailnet
    ];
  };

  networking.firewall.interfaces.eno1.allowedTCPPorts = [6443 10250];
  networking.firewall.interfaces.eno1.allowedUDPPorts = [8472];

  environment.systemPackages = [pkgs.kubectl];

  systemd.tmpfiles.settings = {
    "20-gjermund-ssh" = {
      d = {
        "/home/gjermund/.ssh" = {
          user = "gjermund";
          group = "users";
          mode = "0700";
        };
      };
    };
  };

  # From generated configuration.nix
  networking.networkmanager.enable = true;

  users.users.gjermund = {
    createHome = true;
    extraGroups = ["networkmanager"];
  };
}
