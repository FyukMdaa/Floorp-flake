{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
    pkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});

  in {
    overlays.default = final: prev: {
      floorp-bin-unwrapped = prev.floorp-bin-unwrapped.overrideAttrs (oldAttrs: {
        # sources.json を読み込む
        sources = builtins.fromJSON (builtins.readFile "${self}/sources.json");

        version = sources.version;
        src = final.fetchurl (
          sources.sources.${final.stdenv.hostPlatform.system} or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}")
        );
      });

      floorp-bin = final.wrapFirefox final.floorp-bin-unwrapped {};
    };

    packages = forAllSystems (system: {
      default = (pkgsFor.${system}.extend self.overlays.default).floorp-bin;
    });

    devShells = forAllSystems (system: {
      default = pkgsFor.${system}.mkShell {
        buildInputs = [ (pkgsFor.${system}.extend self.overlays.default).floorp-bin ];
      };
    });
  };
}