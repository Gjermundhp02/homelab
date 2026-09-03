{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../disk-config.nix
    ./arrstack.nix
    ./microvm.nix
    ../crowdsec-bouncer.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = ["/id_ed25519"];
  # This is the actual specification of the secrets.
  sops.secrets."wireguard/private_key" = {};
  sops.secrets.protonvpn = {};
  sops.secrets.ssh = {
    owner = "gjermund";
    mode = "0400";
    path = "/home/gjermund/.ssh/id_ed25519";
  };

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
