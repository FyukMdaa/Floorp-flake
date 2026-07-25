# Floorp Flake

A Nix flake for installing the latest Floorp browser releases on NixOS. This flake incorporates upstream releases more frequently than nixpkgs, allowing you to use the latest version sooner.

It also ships an optional home-manager module for integrating [Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser), a userChrome skin, with support for JS-powered features via fx-autoconfig.

## Features

- **Latest Floorp releases** - Automated daily updates
- **Multi-architecture support** - x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **Natsumi Browser integration** - Optional home-manager module for userChrome theming
- **fx-autoconfig support** - Unlock Natsumi's advanced features (Miniplayer, custom themes, Single Toolbar, etc.)

## Quick Start

### NixOS (with overlay)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [ floorp.overlays.default ];
          environment.systemPackages = [ pkgs.floorp-bin ];
        }
      ];
    };
  };
}
```

### Home-manager (with overlay)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { nixpkgs, floorp, home-manager, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit floorp; };

      modules = [
        {
          nixpkgs.overlays = [ floorp.overlays.default ];
          home.packages = [ pkgs.floorp-bin ];
        }
      ];
    };
  };
}
```

### Direct package reference (without overlay)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [ floorp.packages.x86_64-linux.floorp ];
        }
      ];
    };
  };
}
```

## Natsumi Browser

This flake includes a home-manager module for installing Natsumi Browser and optionally enabling its JS-powered features via fx-autoconfig.

### Basic Setup (theme only)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { nixpkgs, floorp, home-manager, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      modules = [
        floorp.homeModules.floorp
        {
          nixpkgs.overlays = [ floorp.overlays.default ];

          programs.floorp-bin = {
            enable = true;
            natsumi = {
              enable = true;
              profiles = [ "abcd1234.default-release" ];
            };
          };
        }
      ];
    };
  };
}
```

### Advanced Setup (with fx-autoconfig)

```nix
programs.floorp-bin = {
  enable = true;
  natsumi = {
    enable = true;
    profiles = [ "abcd1234.default-release" ];
    
    # Enable JS-powered features: Miniplayer, custom themes, Single Toolbar, etc.
    append.enable = true;
    
    # Optional: configure Natsumi preferences per-profile
    settings = {
      "abcd1234.default-release" = {
        "natsumi.theme.type" = "gradient";
        "natsumi.theme.accent-color" = "sky-blue";
      };
    };
  };
};
```

**Note**: Find your profile directory name under `~/.floorp` — it's the folder containing `prefs.js`.

See [`modules/floorp.nix`](./modules/floorp.nix) for complete option documentation.

## Project Structure

```
.
├── flake.nix                 # Flake definition
├── sources.json              # Floorp version, URL, hash
├── natsumi-sources.json      # Natsumi Browser & fx-autoconfig version, URL, hash
├── modules/
│   └── floorp.nix            # home-manager module (programs.floorp-bin)
├── .github/
│   └── workflows/
│       └── update.yml        # Automated update workflow
└── README.md
```

## Automated Updates

The `.github/workflows/update.yml` workflow:
- Runs daily at 03:00 UTC (can also be triggered manually)
- Fetches latest Floorp, Natsumi Browser, and fx-autoconfig releases
- Updates `sources.json` and `natsumi-sources.json` automatically
- **Commits directly to the default branch** (no PR review step)

### Customizing the Update Process

If you'd rather review changes before they land, fork the repository and modify the final step of `update.yml` to create a pull request instead of pushing directly.

## Acknowledgments

- **[Floorp](https://github.com/Floorp-Projects/Floorp)** - The best browser
- **[Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser)** - A userChrome skin for Firefox and Floorp
- **[fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig)** - Autoloads JS files for browser UI customization
- **[nixpkgs/floorp-bin-unwrapped](https://github.com/NixOS/nixpkgs/blob/HEAD/pkgs/by-name/fl/floorp-bin-unwrapped/)** - Floorp package in nixpkgs
- **[nixpkgs/firefox-wrapper.nix](https://github.com/NixOS/nixpkgs/blob/HEAD/pkgs/applications/networking/browsers/firefox/wrapper.nix)** - Firefox wrapper utilities
