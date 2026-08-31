{host, pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.hostName = host;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
    };
  };
  services.crowdsec = {
    enable = true;
    settings = {
      general.api.server.enable = true;
      lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
    };
    hub.collections = [
      "crowdsecurity/linux"
      "crowdsecurity/sshd"
    ];
    localConfig = {
      acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
      ];
      postOverflows.s01Whitelist = [
        {
          name = "whitelist_private_networks";
          description = "Whitelist RFC1918 and Tailscale CGNAT range from bans";
          whitelist = {
            reason = "private/tailscale network";
            cidr = [
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "100.64.0.0/10"  # Tailscale
            ];
          };
        }
      ];
      profiles = [
        {
          name = "default_ip_remediation";
          filters = [ "Alert.Remediation == true && Alert.GetScope() == \"Ip\"" ];
          decisions = [ { type = "ban"; duration = "4h"; } ];
          on_success = "break";
        }
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  users.users = {
    gjermund = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = let
      authorizedKeys = builtins.fetchurl {
        url = "https://github.com/gjermundhp02.keys";
        sha256 = "sha256:0ysbal2gyixcd3lbj2r41bf273rinnvdhxm6k7q70h72wkfribgc";
      };
    in
      pkgs.lib.splitString "\n" (builtins.readFile authorizedKeys);
    };
  };
  nix.settings.trusted-users = [
    "gjermund"
  ];
  system.stateVersion = "25.11";
}