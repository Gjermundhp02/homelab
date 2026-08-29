{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./arrstack.nix
    ./microvm.nix
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

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  systemd.tmpfiles.settings = {
    "10-mypackage" = {
      d = {
        "/nfs/proxmox" = {
          group = "users";
          user = "nixos";
        };
      };
    };
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

  services.nfs.server = {
    enable = true;
    exports = ''
      /nfs *(rw,sync,no_subtree_check,no_root_squash)
      /nfs/proxmox 192.168.0.0/24(rw,sync,insecure,no_subtree_check,no_root_squash) 10.50.0.2/24(rw,sync,insecure,no_subtree_check,no_root_squash)
    '';
  };

  # networking.wireguard.interfaces = {
  #   wg1 = {
  #     ips = ["10.50.0.1/24"];
  #     listenPort = 51820;

  #     privateKeyFile = config.sops.secrets."wireguard/private_key".path;

  #     peers = [
  #       {
  #         # Proxmox node
  #         publicKey = "CMY4RuvynPyXhRvSPKAt83HYdLGFarc382pjvUtWGCo=";
  #         allowedIPs = ["10.50.0.2/32"];
  #       }
  #     ];
  #   };
  # };

  # networking.firewall = {
  #   allowedUDPPorts = [2049 51820 ];
  #   allowedTCPPorts = [2049];
  # };

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
    createHome = true;
    extraGroups = ["networkmanager"];
  };
}
