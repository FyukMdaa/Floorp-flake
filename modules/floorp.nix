# home-manager module for Floorp, with optional Natsumi Browser theming.
# https://github.com/greeeen-dev/natsumi-browser
#
# Usage:
#
#   { pkgs, ... }: {
#     imports = [ floorp.homeModules.floorp ];
#     nixpkgs.overlays = [ floorp.overlays.default ];
#
#     programs.floorp = {
#       enable = true;
#       natsumi = {
#         enable = true;
#         profiles = [ "abcd1234.default-release" ]; # find this under ~/.floorp
#         append.enable = true; # JS-powered features via fx-autoconfig
#       };
#     };
#   }
#
# `self` is the flake itself, passed in from flake.nix so the module can read
# the version/hash pins from sources.json / natsumi-sources.json.
{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.floorp;

  natsumiSources = builtins.fromJSON (builtins.readFile "${self}/natsumi-sources.json");

  natsumiSrc = pkgs.stdenvNoCC.mkDerivation {
    pname = "natsumi-browser-source";
    version = natsumiSources.natsumi.version;
    src = pkgs.fetchurl {
      url = natsumiSources.natsumi.url;
      sha256 = natsumiSources.natsumi.sha256;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p "$out"
      cp -r . "$out/"
    '';
  };

  fxAutoconfigSrc = pkgs.stdenvNoCC.mkDerivation {
    pname = "fx-autoconfig-source";
    version = natsumiSources.fx-autoconfig.rev;
    src = pkgs.fetchurl {
      url = natsumiSources.fx-autoconfig.url;
      sha256 = natsumiSources.fx-autoconfig.sha256;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p "$out"
      cp -r . "$out/"
    '';
  };

  # The chrome.manifest Natsumi's own README asks you to use once
  # fx-autoconfig (Natsumi Append) is installed on top of Natsumi Browser.
  natsumiAppendManifest = ''
    content userchromejs ./
    content userscripts ../natsumi/scripts/
    skin userstyles classic/1.0 ../CSS/
    content userchrome ../resources/
    content natsumi ../natsumi/
    content natsumi-icons ../natsumi/icons/
  '';

  # fx-autoconfig's `profile/chrome/utils` already ships its own
  # chrome.manifest; we need Natsumi's variant instead. Build a single
  # pre-composed directory rather than symlinking the whole tree AND
  # separately declaring chrome.manifest -- doing both at once makes
  # home-manager try to manage the same path two different ways
  # (recursive symlink vs. a plain file), which fails at activation time.
  natsumiAppendUtilsDir = pkgs.runCommand "natsumi-append-utils" { } ''
    mkdir -p "$out"
    cp -r ${fxAutoconfigSrc}/profile/chrome/utils/. "$out/"
    chmod -R u+w "$out"
    rm -f "$out/chrome.manifest"
    cat > "$out/chrome.manifest" <<'MANIFEST'
    ${natsumiAppendManifest}
    MANIFEST
  '';

  # The final Floorp package: `cfg.package` (defaults to pkgs.floorp-bin from
  # this flake's overlay) wrapped with fx-autoconfig's config.js when Natsumi
  # Append is requested, so `programs.floorp.natsumi.append.enable` is the
  # single switch controlling both the package and the profile-side files.
  finalPackage =
    if cfg.natsumi.enable && cfg.natsumi.append.enable then
      cfg.package.override (old: {
        extraPrefsFiles = (old.extraPrefsFiles or [ ]) ++ [ "${fxAutoconfigSrc}/program/config.js" ];
      })
    else
      cfg.package;

  mkProfileConfig = profile:
    let
      chromeDir = "${cfg.natsumi.browserDir}/${profile}/chrome";
    in
    lib.mkMerge [
      {
        "${chromeDir}/natsumi-config.css".source = "${natsumiSrc}/natsumi-config.css";
        "${chromeDir}/userChrome.css".source = "${natsumiSrc}/userChrome.css";
        "${chromeDir}/userContent.css".source = "${natsumiSrc}/userContent.css";
        "${chromeDir}/natsumi" = {
          source = "${natsumiSrc}/natsumi";
          recursive = true;
        };
      }
      (lib.mkIf cfg.natsumi.append.enable {
        "${chromeDir}/utils".source = natsumiAppendUtilsDir;
        "${chromeDir}/resources" = {
          source = "${fxAutoconfigSrc}/profile/chrome/resources";
          recursive = true;
        };
      })
    ];
in
{
  options.programs.floorp-bin = {
    enable = lib.mkEnableOption "Floorp browser";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.floorp-bin or (throw ''
        programs.floorp.enable is set but pkgs.floorp-bin doesn't exist.
        Add `nixpkgs.overlays = [ floorp.overlays.default ];` (where `floorp`
        is this flake), or set programs.floorp.package yourself.
      '');
      defaultText = lib.literalExpression "pkgs.floorp-bin (from this flake's overlay)";
      description = "The Floorp package to install.";
    };

    natsumi = {
      enable = lib.mkEnableOption "Natsumi Browser, a userChrome skin for Floorp";

      profiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "abcd1234.default-release" ];
        description = ''
          Profile directory names (relative to `browserDir`) to install
          Natsumi Browser into. Find yours under `browserDir` -- it's the
          folder that contains `prefs.js`.
        '';
      };

      browserDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.floorp";
        description = "Root directory containing Floorp's profiles.";
      };

      append.enable = lib.mkEnableOption ''
        Natsumi Append, which unlocks Natsumi's JS-powered features
        (Miniplayer, custom themes, Single Toolbar, ...) via fx-autoconfig.
        Wires up both the profile-side files and the Floorp package itself
        (via extraPrefsFiles) -- no separate package selection needed
      '';

      settings = lib.mkOption {
        type = with lib.types; attrsOf (attrsOf (oneOf [ bool int str ]));
        default = { };
        example = lib.literalExpression ''
          {
            "abcd1234.default-release" = {
              "natsumi.theme.type" = "gradient";
              "natsumi.theme.accent-color" = "sky-blue";
            };
          }
        '';
        description = ''
          Per-profile `about:config` preferences for Natsumi (the
          `natsumi.*` keys documented in Natsumi's README), written to each
          profile's `user.js`. Only touches profiles that have an entry here.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ finalPackage ];
    }

    (lib.mkIf cfg.natsumi.enable {
      assertions = [{
        assertion = cfg.natsumi.profiles != [ ];
        message = "programs.floorp.natsumi.enable is set but programs.floorp.natsumi.profiles is empty; add the profile folder name(s) under ${cfg.natsumi.browserDir}.";
      }];

      home.file = lib.mkMerge (map mkProfileConfig cfg.natsumi.profiles);
    })

    (lib.mkIf (cfg.natsumi.enable && cfg.natsumi.settings != { }) {
      home.file = lib.mkMerge (lib.mapAttrsToList
        (profile: prefs: {
          "${cfg.natsumi.browserDir}/${profile}/user.js".text =
            lib.concatStrings (lib.mapAttrsToList
              (name: value: ''user_pref("${name}", ${builtins.toJSON value});'' + "\n")
              prefs);
        })
        cfg.natsumi.settings);
    })
  ]);
}
