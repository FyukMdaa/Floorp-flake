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
      sources = builtins.fromJSON (builtins.readFile "${self}/sources.json");
      natsumiSources = builtins.fromJSON (builtins.readFile "${self}/natsumi-sources.json");
    
      floorp-bin-unwrapped = prev.floorp-bin-unwrapped.overrideAttrs (oldAttrs: {
        version = final.sources.version;
        src = final.fetchurl (
          final.sources.sources.${final.stdenv.hostPlatform.system} or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}")
        );
      });
    
      floorp-bin = final.wrapFirefox final.floorp-bin-unwrapped {};
    
      # fx-autoconfig source, used to load Natsumi Append's JS features into
      # Floorp itself (see modules/natsumi-browser.nix for the profile side).
      fx-autoconfig-source = final.stdenvNoCC.mkDerivation {
        pname = "fx-autoconfig-source";
        version = final.natsumiSources.fx-autoconfig.rev;
        src = final.fetchurl {
          url = final.natsumiSources.fx-autoconfig.url;
          sha256 = final.natsumiSources.fx-autoconfig.sha256;
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p "$out"
          cp -r . "$out/"
        '';
      };
    
      # Floorp, pre-wired to load fx-autoconfig so Natsumi Append's JS-powered
      # features (Miniplayer, custom themes, Single Toolbar, ...) work. Pair
      # with `programs.natsumi-browser.append.enable = true` in the
      # home-manager module, which installs the matching profile-side files.
      floorp-bin-natsumi = final.floorp-bin.override (old: {
        extraPrefsFiles = (old.extraPrefsFiles or [ ]) ++ [ "${final.fx-autoconfig-source}/program/config.js" ];
      });
    };
    
    packages = forAllSystems (system: let
      pkgs = pkgsFor.${system}.extend self.overlays.default;
    in {
      default = pkgs.floorp-bin;
      floorp-bin-natsumi = pkgs.floorp-bin-natsumi;
    });

    devShells = forAllSystems (system: {
      default = pkgsFor.${system}.mkShell {
        buildInputs = [ (pkgsFor.${system}.extend self.overlays.default).floorp-bin ];
      };
    });

    homeModules = {
      natsumi-browser = import ./modules/natsumi-browser.nix { inherit self; };
      default = self.homeModules.natsumi-browser;
    };
  };
}
