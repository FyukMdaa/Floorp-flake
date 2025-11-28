{ stdenv
, fetchurl
, lib
, autoPatchelfHook
, wrapGAppsHook3
, alsa-lib
, atk
, cairo
, curl
, dbus
, dbus-glib
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gtk3
, libxkbcommon
, libX11
, libXcomposite
, libXcursor
, libXdamage
, libXext
, libXfixes
, libXi
, libXrandr
, libXrender
, libXtst
, mesa
, nspr
, nss
, pango
, pipewire
, systemd
, wayland
}:

stdenv.mkDerivation rec {
  pname = "floorp";
  version = "12.7.0";

  src = fetchurl {
    url = "https://github.com/Floorp-Projects/Floorp/releases/download/v${version}/floorp-linux-x86_64.tar.xz";
    hash = "sha256-jpfLrHCQzDc062POI+aUlaAIDciBxhI7GzsYvHtt72I=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    curl
    dbus
    dbus-glib
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libxkbcommon
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    mesa
    nspr
    nss
    pango
    pipewire
    stdenv.cc.cc
    systemd
    wayland
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/floorp
    cp -r * $out/lib/floorp

    mkdir -p $out/bin
    ln -s $out/lib/floorp/floorp $out/bin/floorp

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
  };
}