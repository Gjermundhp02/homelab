{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../disk-config.nix
    ./arrstack.nix
    ./microvm.nix
    ./crowdsec.nix
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
