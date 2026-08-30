{...}: {
  imports = [
    ./microvm/immich.nix
  ];
  networking.useNetworkd = true;

  systemd.network.enable = true;

  networking.nat = {
    enable = true;
    externalInterface = "wlp1s0";
    internalInterfaces = ["microbr0" "eno1"];
    forwardPorts = [
      {
        sourcePort = 25565;
        destination = "192.168.101.20:25565";
        proto = "tcp";
      }
    ];
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts = [25565];
    extraForwardRules = ''
      # VM bridge -> internet
      iifname "microbr0" oifname "wlp1s0" accept
      iifname "wlp1s0" oifname "microbr0" ct state established,related accept

      # device on eno1 -> internet
      iifname "eno1" oifname "wlp1s0" accept
      iifname "wlp1s0" oifname "eno1" ct state established,related accept

      # port-forwarded 25565 from wlp1s0/tailscale0 to compute via eno1
      iifname { "wlp1s0", "tailscale0" } oifname "eno1" tcp dport 25565 accept

      # Tailscale -> VM network
      iifname "tailscale0" oifname "microbr0" accept
      iifname "microbr0" oifname "tailscale0" ct state established,related accept
    '';
  };

  # Direct NAT rule for incoming Tailscale traffic -> compute game-server
  networking.nftables = {
    enable = true;
    tables.tailscale-dnat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          iifname "tailscale0" tcp dport 25565 dnat to 192.168.101.20:25565
        }
      '';
    };
  };

  systemd.network.netdevs."10-microbr0" = {
    netdevConfig = {
      Name = "microbr0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."10-microbr0" = {
    matchConfig.Name = "microbr0";
    networkConfig = {
      Address = ["192.168.100.1/24"];
    };
  };

  systemd.network.networks."10-vm-web" = {
    matchConfig.Name = "vm-web";
    networkConfig = {
      Bridge = "microbr0";
    };
  };

  networking.networkmanager.unmanaged = [ "eno1" ];

  systemd.network.networks."10-eno1" = {
    matchConfig.Name = "eno1";
    networkConfig = {
      Address = ["192.168.101.1/24"];
    };
  };
}
