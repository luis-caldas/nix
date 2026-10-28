{
  lib,
  rustPlatform,
  cmake,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  dbus,
  glib-networking,
  gst_all_1,
}:

let
  src = builtins.fetchGit {
    url = "https://github.com/jm2/tributary.git";
    rev = "1a61fd97380c593c7630c2d8a15541efae157a16";
  };

  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];
in

rustPlatform.buildRustPackage {
  pname = "tributary";
  version = "0.7.2";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    dbus
    glib-networking
  ] ++ gstPlugins;

  GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins;

  doCheck = false;

  postInstall = ''
    install -Dm644 \
      data/io.github.jm2.tributary.desktop \
      $out/share/applications/io.github.jm2.tributary.desktop

    install -Dm644 \
      data/io.github.jm2.tributary.metainfo.xml \
      $out/share/metainfo/io.github.jm2.tributary.metainfo.xml

    for size in 16 24 32 48 64 128 256 512; do
      install -Dm644 \
        "data/icons/hicolor/''${size}x''${size}/apps/io.github.jm2.tributary.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/io.github.jm2.tributary.png"
    done

    install -Dm644 \
      data/icons/hicolor/scalable/actions/io.github.jm2.tributary-equalizer-symbolic.svg \
      $out/share/icons/hicolor/scalable/actions/io.github.jm2.tributary-equalizer-symbolic.svg
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"
    )
  '';

  meta = {
    description = "Rhythmbox-style multi-source music manager";
    homepage = "https://github.com/jm2/tributary";
    license = lib.licenses.gpl3Plus;
    mainProgram = "tributary";
    platforms = lib.platforms.linux;
  };
}
