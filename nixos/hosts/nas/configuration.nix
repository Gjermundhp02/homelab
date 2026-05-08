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
  sops.age.sshKeyPaths = [ "/id_ed25519" ];
  # This is the actual specification of the secrets.
  sops.secrets."wireguard/private_key" = {};

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
    wg0 = {
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
    allowedUDPPorts = [2049 51820];
    allowedTCPPorts = [2049];
  };
}
