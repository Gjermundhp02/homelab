{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

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
  systemd.network.networks."10-enp2s0" = {
    matchConfig.Name = "enp2s0";
    networkConfig = {
      Address = [ "192.168.101.2/24" ];
      Gateway = "192.168.101.1";
    };
  };

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
