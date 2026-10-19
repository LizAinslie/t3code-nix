{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, glib, gtk3, pango, cairo, at-spi2-core, nss, nspr, expat, dbus, cups
, alsa-lib, libgbm, libxkbcommon, libsecret, udev, xorg }:

stdenv.mkDerivation (finalAttrs: {
  pname = "t3code";
  version = "0.1.0";

  meta = {
    description = "The open-source control plane for coding agents";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
    sourceProvenance = [
      lib.sourceTypes.binaryNativeCode
    ];
  };

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${finalAttrs.version}/T3-Code-${finalAttrs.version}-amd64.deb";
    hash = "sha256-NZCmPC61vuIbcLIppFhjIu2CFArs2Mf+sJqoAXj4Y5w=";
  };

  # build tools
  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [
    stdenv.cc.cc.lib # libgcc_s, libstdc++
      glib gtk3 pango cairo
      at-spi2-core # libatk, libatk-bridge, libatspi
      nss nspr expat dbus cups alsa-lib
      libgbm libxkbcommon libsecret
      udev
      xorg.libX11 xorg.libxcb xorg.libXext xorg.libXfixes
      xorg.libXrandr xorg.libXdamage xorg.libXcomposite
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    cp -r "opt/T3 Code (Beta)" $out/opt/t3code
    cp -r usr/share $out/share
    substituteInPlace $out/share/applications/t3code.desktop \
      --replace-fail '"/opt/T3 Code (Beta)/t3code"' t3code
    find $out/opt/t3code -type d \( -name '*-musl' -o -name 'linux-arm64' \) -prune -exec rm -rf {} +
    makeWrapper $out/opt/t3code/t3code $out/bin/t3code \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    runHook postInstall
    '';
})
