{config, ...}: let
  immichSecretsPath = config.sops.secrets.immich.path;
in {
  sops.secrets.immich = {};
  systemd.tmpfiles.settings = {
    "10-microvm-immich" = {
      d = {
        "/var/lib/microvms/immich/data" = {
          user = "root";
          group = "root";
        };
      };
    };
  };

  services.caddy = {
    virtualHosts = {
      "immich.hpedersen.no".extraConfig = ''
        reverse_proxy 192.168.100.10:2283
      '';
    };
  };

  # Declarative MicroVM definitions
  microvm.vms = {
    immich = {
      # Keep the VM auto-starting with systemd on boot
      autostart = true;

      # The NixOS configuration inside the guest VM
      config = {lib, ...}: let
        gjermundKeys = import ../../../lib/gjermund-keys.nix {inherit lib;};
      in {
        # Import microvm guest capabilities inside the guest block
        microvm = {
          hypervisor = "cloud-hypervisor"; # "qemu", "cloud-hypervisor", "firecracker", "crosvm"
          vsock.cid = 3;
          vcpu = 2;
          mem = 4 * 1024; # MB

          # Persistent storage shared from host via virtiofs
          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "secrets";
              source = "/run/secrets";
              mountPoint = "/run/secrets";
            }
            {
              proto = "virtiofs";
              tag = "data";
              source = "/var/lib/microvms/immich/data";
              mountPoint = "/var/lib/immich";
            }
          ];

          # Attach guest interface to the host bridge
          interfaces = [
            {
              type = "tap";
              id = "vm-web";
              mac = "02:00:00:00:00:01";
            }
          ];
        };

        security.sudo.wheelNeedsPassword = false;
        users.users = {
          gjermund = {
            isNormalUser = true;
            extraGroups = ["wheel"];
            openssh.authorizedKeys.keys = gjermundKeys;
          };
        };
        nix.settings.trusted-users = [
          "gjermund"
        ];

        # Standard Guest NixOS options
        system.stateVersion = "26.05";
        networking.hostName = "immich";
        networking.useNetworkd = true;

        systemd.network.enable = true;

        systemd.network.networks."20-lan" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = ["192.168.100.10/24"];
            Gateway = "192.168.100.1";
            DHCP = "no";
          };
        };

        services.immich = {
          enable = true;
          host = "0.0.0.0";
          openFirewall = true;
          secretsFile = immichSecretsPath;
        };

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
        };
        services.fail2ban.enable = true;
      };
    };
  };
}