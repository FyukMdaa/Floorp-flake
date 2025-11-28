{
  description = "Floorp browser - A customizable Firefox fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} = {
        floorp = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        default = self.packages.${system}.floorp;
      };

      overlays.default = final: prev: {
        # `self.packages`を参照せず、直接パッケージを定義する
        floorp = final.callPackage ./package.nix { };
      };
      
      # `floorp.overlay` でアクセスできるようにする
      floorp = {
        overlay = self.overlays.default;
      };

      # NixOSモジュールも標準通りに提供
      nixosModules.default = { config, lib, pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}