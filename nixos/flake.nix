{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixarr.url = "github:Gjermundhp02/nixarr/wip-natpmp";
  };

  outputs = {
    nixpkgs,
    disko,
    sops-nix,
    nixarr,
    ...
  }: {
    nixosConfigurations = let
      # Fetch all of the directories in the hosts folder
      hosts = builtins.attrNames (nixpkgs.lib.filterAttrs (n: t: t == "directory") (builtins.readDir ./hosts));
    in
      # Map the hosts to nixosConfigurations
      builtins.listToAttrs
      (map
        (host: {
          name = host;
          value = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit host;
            };
            modules = [
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              nixarr.nixosModules.default
              ./common.nix
              (./hosts + "/${host}/configuration.nix")
            ];
          };
        })
        hosts);
  };
}
