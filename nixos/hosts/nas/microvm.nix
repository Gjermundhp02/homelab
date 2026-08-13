{ config, ... }:

let
  immichSecretsPath = config.sops.secrets.immich.path;
in
{
  sops.secrets.immich = {};
  # Configure host networking/bridge for the VMs if needed
  networking.bridges.microbr0.interfaces = [ "vm-web" ];
  networking.interfaces.microbr0.ipv4.addresses = [{
    address = "192.168.100.1";
    prefixLength = 24;
  }];

  # Declarative MicroVM definitions
  microvm.vms = {
    immich = {
      # Keep the VM auto-starting with systemd on boot
      autostart = true;

      # The NixOS configuration inside the guest VM
      config = { ... }: {
        # Import microvm guest capabilities inside the guest block
        microvm = {
          hypervisor = "cloud-hypervisor"; # "qemu", "cloud-hypervisor", "firecracker", "crosvm"
          vsock.cid = 3;
          vcpu = 2;
          mem = 2048; # MB

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
              mountPoint = "/var/data";
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

        # Standard Guest NixOS options
        system.stateVersion = "26.05";
        networking.hostName = "immich";

        # Networking inside guest
        networking.interfaces.eth0.ipv4.addresses = [{
          address = "192.168.100.10";
          prefixLength = 24;
        }];
        networking.defaultGateway = {
          address = "192.168.100.1";
          interface = "eth0";
        };

        services.immich = {
          enable = true;
          host = "0.0.0.0";
          openFirewall = true;
          secretsFile = immichSecretsPath;
        };

        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "yes";
        };
      };
    };
  };
}