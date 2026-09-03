{lib}: let
  authorizedKeys = builtins.fetchurl {
    url = "https://github.com/gjermundhp02.keys";
    sha256 = "sha256:0ysbal2gyixcd3lbj2r41bf273rinnvdhxm6k7q70h72wkfribgc";
  };
in
  lib.filter (k: k != "") (lib.splitString "\n" (builtins.readFile authorizedKeys))
