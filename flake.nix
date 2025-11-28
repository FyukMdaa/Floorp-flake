{
  description = "Floorp browser - A customizable Firefox fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        floorp = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.floorp;
      };

      overlays.default = final: prev: {
        floorp = self.packages.${final.system}.floorp;
      };

      # NixOS configuration.nixから使いやすくする
      nixosModules.default = { config, lib, pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}