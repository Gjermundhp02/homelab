{...}: {
  imports = [
    ./microvm/game-server.nix
  ];

  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Bridge enp2s0 and the VM tap onto the same 192.168.101.x segment
  systemd.network.netdevs."10-microbr0" = {
    netdevConfig = {
      Name = "microbr0";
      Kind = "bridge";
    };
  };

  # Bridge gets the host IP and gateway (moved from enp2s0)
  systemd.network.networks."10-microbr0" = {
    matchConfig.Name = "microbr0";
    networkConfig = {
      Address = ["192.168.101.2/24"];
      Gateway = "192.168.101.1";
    };
  };

  # enp2s0 becomes a bridge member - no IP
  systemd.network.networks."10-enp2s0" = {
    matchConfig.Name = "enp2s0";
    networkConfig = {
      Bridge = "microbr0";
    };
  };

  # VM tap also joins the bridge
  systemd.network.networks."10-vm-game" = {
    matchConfig.Name = "vm-game";
    networkConfig = {
      Bridge = "microbr0";
    };
  };
}
