{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, glib, gtk3, pango,
  cairo, at-spi2-core, nss, nspr, expat, dbus, cups, alsa-lib, libgbm,
  libxkbcommon, libsecret, udev, libx11, libxcb, libxext, libxfixes, libxrandr,
  libxdamage, libxcomposite, version ? "0.1.0", url, hash }:

stdenv.mkDerivation (finalAttrs: {
  pname = "t3code";
  version = version;

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
    url = url;
    hash = hash;
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
      libx11 libxcb libxext libxfixes libxrandr libxdamage libxcomposite
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    appdir=$(echo opt/*)   # "opt/T3 Code (Beta)" or "opt/T3 Code (Nightly)"
    cp -r "$appdir" $out/opt/t3code
    cp -r usr/share $out/share
    substituteInPlace $out/share/applications/t3code.desktop \
      --replace-fail "\"/$appdir/t3code\"" t3code
    find $out/opt/t3code -type d \( -name '*-musl' -o -name 'linux-arm64' \) -prune -exec rm -rf {} +
    makeWrapper $out/opt/t3code/t3code $out/bin/t3code \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    runHook postInstall
    '';
})
