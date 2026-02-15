# Floorp Flake

This is a Floorp browser flake for NixOS. It incorporates upstream releases more frequently than nixpkgs, allowing you to use the latest version sooner.

## Usage

### Add to flake.nix

```nix
{
  inputs = {
    nixpkgs.url = “github:NixOS/nixpkgs/nixos-unstable”;
    floorp.url = “github:fyukmdaa/floorp-flake”;
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = “x86_64-linux”;
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

### When using with Home-manager

```nix
{
  inputs = {
    nixpkgs.url = “github:NixOS/nixpkgs/nixos-unstable”;
    floorp.url = “github:fyukmdaa/floorp-flake”;
    home-manager = “github:nix-community/home-manager”;
  };

  outputs = { nixpkgs, floorp, home-manager, ... }: {
    homeConfigurations.“yourusername” = home-manager.lib.homeManagerConfiguration {
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

### When not using overlays

`floorp.packages.x86_64-linux.floorp` directly references the Floorp package from the flake's `outputs.packages`.

```nix
{
  inputs = {
    nixpkgs.url = “github:NixOS/nixpkgs/nixos-unstable”;
    floorp.url = “github:fyukmdaa/floorp-flake”;
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = “x86_64-linux”;
      modules = [
        {
          environment.systemPackages = [ floorp.packages.x86_64-linux.floorp ];
        }
      ];
    };
  };
}
```

## File Structure

```.

├── flake.nix           # flake definition
├── sources.json        # version, URL, hash value definitions
├── .github/
│   └── workflows/
│       └── update.yml  # automatic update workflow
└── README.md
```

## Automatic Updates

~~GitHub Actions automatically checks for the latest Floorp version daily and creates a PR if a new version is found.~~  
We've switched to manual updates. If you need automatic updates, please fork the repository and create a schedule in `.github/workflows/update.yml`.

### How Automatic PR Creation Works

- `.github/workflows/update.yml` checks for new Floorp releases daily at regular intervals.
- If a new version is found, files containing version information (like `sources.json`) are automatically updated, and a PR is created.
- This makes it easy to always get the latest Floorp.

# Acknowledgments
**[Floorp](https://github.com/Floorp-Projects/Floorp)**  
The best browser.  


**[nixpkgs/floorp-bin-unwrapped](https://github.com/NixOS/nixpkgs/tree/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/by-name/fl/floorp-bin-unwrapped)**   
**[nixpkgs/firefox-wrapper.nix](https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/applications/networking/browsers/firefox/wrapper.nix)**   
This was extremely helpful when creating this Flake.
