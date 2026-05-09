{host, pkgs, ...}: {
  imports = [
    ./disk-config.nix
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.hostName = host;
  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users.users = {
    gjermund = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = let
      authorizedKeys = builtins.fetchurl {
        url = "https://github.com/gjermundhp02.keys";
        sha256 = "sha256:0kaccm41fyjy84mxr8c207df817ci8h78ka0fx8l97y6qhlhxxfr";
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