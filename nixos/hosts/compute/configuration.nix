{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./microvm.nix
    ../crowdsec-bouncer.nix  # enable after: cscli bouncers add crowdsec-firewall-bouncer → add key to secrets/secrets.yaml
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/id_ed25519"];
  sops.secrets.ssh = {
    owner = "gjermund";
    mode = "0400";
    path = "/home/gjermund/.ssh/id_ed25519";
  };

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

  users.users.gjermund = {
    createHome = true;
    hashedPassword = "$y$j9T$alon146pbcXNU.dnNeLbe1$BfAEeXwy6ms/B5Z7CeDePw6Z7lfjF0Sxpu676yM1vi3";
  };
}
