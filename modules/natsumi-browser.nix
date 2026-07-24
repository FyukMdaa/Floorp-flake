# home-manager module for https://github.com/greeeen-dev/natsumi-browser
#
# Natsumi Browser is a userChrome.css-based skin for Firefox-based browsers
# (Floorp, Firefox, Waterfox, Librewolf, ...). It's installed by dropping a
# handful of files into a profile's `chrome` folder. This module automates
# that for one or more profiles managed by home-manager.
#
# Usage:
#
#   { pkgs, ... }: {
#     imports = [ floorp.homeModules.natsumi-browser ];
#
#     programs.natsumi-browser = {
#       enable = true;
#       profiles = [ "abcd1234.default-release" ]; # find this under ~/.floorp
#     };
#   }
#
# `self` is the flake itself, passed in from flake.nix so the module can read
# the version/hash pins from natsumi-sources.json without depending on the
# overlay being applied.
{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.natsumi-browser;

  sources = builtins.fromJSON (builtins.readFile "${self}/natsumi-sources.json");

  natsumiSrc = pkgs.stdenvNoCC.mkDerivation {
    pname = "natsumi-browser-source";
    version = sources.natsumi.version;
    src = pkgs.fetchurl {
      url = sources.natsumi.url;
      sha256 = sources.natsumi.sha256;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p "$out"
      cp -r . "$out/"
    '';
  };

  fxAutoconfigSrc = pkgs.stdenvNoCC.mkDerivation {
    pname = "fx-autoconfig-source";
    version = sources.fx-autoconfig.rev;
    src = pkgs.fetchurl {
      url = sources.fx-autoconfig.url;
      sha256 = sources.fx-autoconfig.sha256;
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

  mkProfileConfig = profile:
    let
      chromeDir = "${cfg.browserDir}/${profile}/chrome";
    in
    lib.mkMerge [
      {
        "${chromeDir}/natsumi-config.css".source = "${cfg.package}/natsumi-config.css";
        "${chromeDir}/userChrome.css".source = "${cfg.package}/userChrome.css";
        "${chromeDir}/userContent.css".source = "${cfg.package}/userContent.css";
        "${chromeDir}/natsumi" = {
          source = "${cfg.package}/natsumi";
          recursive = true;
        };
      }
      (lib.mkIf cfg.append.enable {
        "${chromeDir}/utils".source = natsumiAppendUtilsDir;
        "${chromeDir}/resources" = {
          source = "${fxAutoconfigSrc}/profile/chrome/resources";
          recursive = true;
        };
      })
    ];
in
{
  options.programs.natsumi-browser = {
    enable = lib.mkEnableOption "Natsumi Browser, a userChrome skin for Floorp/Firefox-based browsers";

    package = lib.mkOption {
      type = lib.types.package;
      default = natsumiSrc;
      defaultText = lib.literalExpression "natsumi-browser source pinned in natsumi-sources.json";
      description = "Natsumi Browser source tree to install.";
    };

    browserDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.floorp";
      example = "\${config.home.homeDirectory}/.mozilla/firefox";
      description = ''
        Root directory containing the browser's profiles. Defaults to
        Floorp's profile root (`~/.floorp`); set this to `~/.mozilla/firefox`
        or similar if applying Natsumi to a different Firefox-based browser.
      '';
    };

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

    append = {
      enable = lib.mkEnableOption ''
        Natsumi Append, which installs fx-autoconfig alongside Natsumi
        Browser to unlock its JS-powered features (Miniplayer, custom themes,
        Single Toolbar, etc.). This only wires up the profile-side files;
        you must ALSO make your Floorp package load fx-autoconfig's
        program-side config.js -- see `programs.natsumi-browser.append.package`
      '';

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default =
          if pkgs ? floorp-bin then
            pkgs.floorp-bin.override (old: {
              extraPrefsFiles = (old.extraPrefsFiles or [ ]) ++ [ "${fxAutoconfigSrc}/program/config.js" ];
            })
          else
            null;
        defaultText = lib.literalExpression ''
          pkgs.floorp-bin wrapped with fx-autoconfig's program/config.js via
          extraPrefsFiles (requires this flake's overlay to be applied so
          that pkgs.floorp-bin exists)
        '';
        description = ''
          A Floorp package pre-wired to load fx-autoconfig, for use with
          `home.packages`. Only computed automatically when this flake's
          overlay has been applied (so `pkgs.floorp-bin` exists); otherwise
          you need to wrap your own Floorp package the same way and set this
          option yourself.
        '';
      };
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf (attrsOf (oneOf [ bool int str ]));
      default = { };
      example = lib.literalExpression ''
        {
          "abcd1234.default-release" = {
            "natsumi.theme.type" = "gradient";
            "natsumi.theme.accent-color" = "sky-blue";
            "natsumi.tabs.type" = "material";
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.profiles != [ ];
          message = "programs.natsumi-browser.enable is set but programs.natsumi-browser.profiles is empty; add the profile folder name(s) under ${cfg.browserDir}.";
        }
        {
          assertion = !cfg.append.enable || (pkgs ? floorp-bin) || cfg.append.package != null;
          message = ''
            programs.natsumi-browser.append.enable is set, but pkgs.floorp-bin
            doesn't exist and programs.natsumi-browser.append.package wasn't
            set manually. Either apply this flake's `overlays.default`, or
            set append.package yourself.
          '';
        }
      ];

      home.file = lib.mkMerge (map mkProfileConfig cfg.profiles);
    }

    (lib.mkIf (cfg.settings != { }) {
      home.file = lib.mkMerge (lib.mapAttrsToList
        (profile: prefs: {
          "${cfg.browserDir}/${profile}/user.js".text =
            lib.concatStrings (lib.mapAttrsToList
              (name: value: ''user_pref("${name}", ${builtins.toJSON value});'' + "\n")
              prefs);
        })
        cfg.settings);
    })
  ]);
}
