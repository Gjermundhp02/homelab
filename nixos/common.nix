{host, pkgs, ...}: {
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