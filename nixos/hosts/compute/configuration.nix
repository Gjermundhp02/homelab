{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./microvm.nix
    ./crowdsec.nix  # enable after: cscli bouncers add crowdsec-firewall-bouncer → add key to secrets/secrets.yaml
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/id_ed25519"];
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

  # Stage-1 initrd unlock from physical USB
  boot.initrd = {
    kernelModules = [ "uas" "usb_storage" "vfat" ];

    luks.devices = {
      "crypted-root".allowDiscards = true;
      "crypted-raid".allowDiscards = true;
    };
  };

  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  # From generated configuration.nix
  networking.useNetworkd = true;
  systemd.network.enable = true;

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
    hashedPassword = "$y$j9T$alon146pbcXNU.dnNeLbe1$BfAEeXwy6ms/B5Z7CeDePw6Z7lfjF0Sxpu676yM1vi3";
    extraGroups = ["networkmanager"];
  };
}
