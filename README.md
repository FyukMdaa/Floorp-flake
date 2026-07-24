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

## Natsumi Browser (home-manager module)

This flake also ships a home-manager module that installs
[Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser), a
userChrome skin, into one or more of your browser profiles.

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
        floorp.homeModules.natsumi-browser
        {
          nixpkgs.overlays = [ floorp.overlays.default ]; # needed for append.enable
          home.packages = [ pkgs.floorp-bin ];

          programs.natsumi-browser = {
            enable = true;
            # Folder name(s) under ~/.floorp (or `browserDir`) containing your profile(s).
            profiles = [ "abcd1234.default-release" ];

            # Optional: unlock Natsumi's JS-powered features (Miniplayer, custom
            # themes, Single Toolbar, ...) via fx-autoconfig. Requires the overlay
            # above so `pkgs.floorp-bin` exists; use `append.package` in home.packages.
            append.enable = false;

            settings = {
              "abcd1234.default-release" = {
                "natsumi.theme.type" = "gradient";
                "natsumi.theme.accent-color" = "sky-blue";
              };
            };
          };
        }
      ];
    };
  };
}
```

See `modules/natsumi-browser.nix` for the full option list and doc comments.

## File Structure

```.

├── flake.nix               # flake definition
├── sources.json            # Floorp version, URL, hash value definitions
├── natsumi-sources.json     # Natsumi Browser / fx-autoconfig version, URL, hash definitions
├── modules/
│   └── natsumi-browser.nix # home-manager module (programs.natsumi-browser)
├── .github/
│   └── workflows/
│       └── update.yml      # automatic update workflow
└── README.md
```

## Automatic Updates

`.github/workflows/update.yml` runs daily (and can also be triggered manually)
to check for new Floorp, Natsumi Browser, and fx-autoconfig releases. When a
new version is found, `sources.json` / `natsumi-sources.json` are regenerated
and **committed directly to this branch** by `github-actions[bot]` -- no PR,
no manual merge required.

If you'd rather review changes before they land, fork the repository and
change the last step of `update.yml` to open a pull request instead of
pushing directly.

# Acknowledgments
**[Floorp](https://github.com/Floorp-Projects/Floorp)**  
The best browser.  

**[natsumi-browser](https://github.com/greeeen-dev/natsumi-browser)**

**[nixpkgs/floorp-bin-unwrapped](https://github.com/NixOS/nixpkgs/tree/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/by-name/fl/floorp-bin-unwrapped)**   
**[nixpkgs/firefox-wrapper.nix](https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/applications/networking/browsers/firefox/wrapper.nix)**   
This was extremely helpful when creating this Flake.
