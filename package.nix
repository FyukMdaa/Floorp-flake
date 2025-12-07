{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  patchelfUnstable,
  writeText,

  # Build Inputs
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  curl,
  dbus,
  dbus-glib,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libglvnd,
  libpulseaudio,
  libdrm,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libXtst,
  mesa,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  wayland,
  zlib,
  adwaita-icon-theme,
  libva,
}:

let
  policies = {
    DisableAppUpdate = true;
    DisableTelemetry = true;
  };
  policiesJson = writeText "floorp-policies.json" (builtins.toJSON { inherit policies; });

in
stdenv.mkDerivation rec {
  pname = "floorp";
  version = "12.8.3";

  src = fetchurl {
    url = "https://github.com/Floorp-Projects/Floorp/releases/download/v${version}/floorp-linux-x86_64.tar.xz";
    hash = "sha256-DmZCyFhP3N6VPTR3OeuHyrLmvcfUZXHeLsn/TTu+I10=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    patchelfUnstable
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus-glib
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libpulseaudio
    libXtst
    adwaita-icon-theme
  ];

  runtimeDependencies = [
    curl
    pciutils
    libva.out
  ];

  appendRunpaths = [
    "${pipewire}/lib"
  ];

  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    rm -v updater updater.ini icons/updater.png update-settings.ini

    mkdir -p $out/lib/floorp
    cp -r . $out/lib/floorp

    mkdir -p $out/bin
    ln -s $out/lib/floorp/floorp $out/bin/floorp

    mkdir -p $out/lib/floorp/distribution
    ln -s ${policiesJson} $out/lib/floorp/distribution/policies.json

    # Desktop entry
    mkdir -p $out/share/applications
    cat > $out/share/applications/floorp.desktop <<EOF
    [Desktop Entry]
    Version=1.0
    Name=Floorp
    GenericName=Web Browser
    Comment=Browse the World Wide Web
    Exec=$out/bin/floorp %u
    Icon=floorp
    Terminal=false
    Type=Application
    Categories=Network;WebBrowser;
    MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;x-scheme-handler/http;x-scheme-handler/https;
    StartupNotify=true
    EOF

    # Icon
    mkdir -p $out/share/icons/hicolor/128x128/apps
    ln -s $out/lib/floorp/browser/chrome/icons/default/default128.png \
      $out/share/icons/hicolor/128x128/apps/floorp.png

    runHook postInstall
  '';

  meta = with lib; {
    description = "A customizable Firefox fork with advanced features";
    homepage = "https://floorp.app/";
    license = licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "floorp";
  };
}
