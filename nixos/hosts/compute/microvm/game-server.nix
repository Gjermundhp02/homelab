{
  pkgs,
  config,
  ...
}: let
  minecraftEnvFile = config.sops.secrets.minecraft.path;
  playitEnvFile = config.sops.secrets.playit.path;
in {

  sops.secrets.minecraft = {
    sopsFile = ../secrets/game-server/minecraft.env;
    format = "dotenv";
  };

  sops.secrets.playit = {
    sopsFile = ../secrets/game-server/game-server.yaml;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/microvms 0755 root root -"
    "d /var/lib/microvms/game-server 0755 root root -"
    "d /var/lib/microvms/game-server/data 0755 root root -"
    "d /var/lib/microvms/game-server/data/minecraft-data 0755 root root -"
  ];

  # Declarative MicroVM definitions
  microvm.vms = {
    game-server = {
      autostart = true;

      config = {...}: {
        microvm = {
          hypervisor = "cloud-hypervisor";
          vsock.cid = 3;
          vcpu = 4;
          mem = 16 * 1024; # MB

          shares = [
            {
              proto = "virtiofs";
              tag = "game-ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "game-secrets";
              source = "/run/secrets";
              mountPoint = "/run/secrets";
            }
            {
              proto = "virtiofs";
              tag = "game-data";
              source = "/var/lib/microvms/game-server/data";
              mountPoint = "/var/lib/game-server";
            }
          ];

          volumes = [
            {
              label = "root";
              image = "root.img";
              size = 10240; # MiB
              mountPoint = "/";
            }
          ];

          interfaces = [
            {
              type = "tap";
              id = "vm-game";
              mac = "02:00:00:00:00:02";
            }
          ];
        };

        security.sudo.wheelNeedsPassword = false;
        users.users = {
          gjermund = {
            isNormalUser = true;
            extraGroups = ["wheel" "docker"];
            openssh.authorizedKeys.keys = [(builtins.readFile ../ssh.pub)];
          };
        };
        nix.settings.trusted-users = [
          "gjermund"
        ];

        system.stateVersion = "26.05";
        networking.hostName = "game-server";
        networking.useNetworkd = true;
        networking.nameservers = ["1.1.1.1" "8.8.8.8"];

        systemd.network.enable = true;

        systemd.network.networks."20-lan" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = ["192.168.101.20/24"];
            Gateway = "192.168.101.1";
            DNS = ["1.1.1.1" "8.8.8.8"];
            DHCP = "no";
          };
        };

        virtualisation.oci-containers = {
          backend = "podman";
          containers = {
            playit = {
              image = "ghcr.io/playit-cloud/playit-agent:1.0";
              extraOptions = ["--network=host" "--env-file=${playitEnvFile}"];
            };
            minecraft = {
              autoStart = true;
              image = "docker.io/itzg/minecraft-server:java17";
              environment = {
                EULA = "TRUE";
                ENABLE_RCON = "true";
                RCON_PORT = "25575";
                SERVER_PORT = "25565";
                MAX_PLAYERS = "10";
                MOTD = "The ISSO server";
                TYPE = "AUTO_CURSEFORGE";
                CF_SLUG = "all-the-mods-9";
                MEMORY = "12G";
              };
              extraOptions = [
                "--network=host"
                "--env-file=${minecraftEnvFile}"
              ];
              volumes = [
                "/var/lib/game-server/minecraft-data:/data"
              ];
            };
          };
        };
        networking.firewall.allowedTCPPorts = [25565 25575];

        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "yes";
        };
      };
    };
  };
}
