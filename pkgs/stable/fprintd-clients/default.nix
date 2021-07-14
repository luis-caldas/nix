{ lib, stdenv
, fetchFromGitLab
, pkg-config
, gobject-introspection
, meson
, ninja
, perl
, gettext
, cairo
, gtk-doc
, libxslt
, docbook-xsl-nons
, docbook_xml_dtd_412
, fetchurl
, glib
, gusb
, dbus
, dbus-glib
, libpam-wrapper
, polkit
, nss
, pam
, systemd
, libfprint
, python3
}:

stdenv.mkDerivation rec {

  pname = "fprintd-clients";
  version = "1.90.1";
  outputs = [ "out" "devdoc" ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "uunicorn";
    repo = "fprintd";
    rev = "${version}";
    sha256 = "0mbzk263x7f58i9cxhs44mrngs7zw5wkm62j5r6xlcidhmfn03cg";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    perl # for pod2man
    gettext
    gtk-doc
    libxslt
    # TODO: apply this to D-Bus so that other packages can benefit.
    # https://gitlab.freedesktop.org/dbus/dbus/-/merge_requests/202
    (dbus.overrideAttrs (attrs: {
      postInstall = attrs.postInstall or "" + ''
        ln -s ${fetchurl {
          url = "https://gitlab.freedesktop.org/dbus/dbus/-/raw/b207135dbd8c09cf8da28f7e3b0a18bb11483663/doc/catalog.xml";
          sha256 = "1/43XwAIcmRXfM4OXOPephyQyUnW8DSveiZbiPvW72I=";
        }} $out/share/xml/dbus-1/catalog.xml
      '';
    }))
    docbook-xsl-nons
    docbook_xml_dtd_412
  ];

  buildInputs = [
    glib
    dbus-glib
    polkit
    nss
    pam
    libpam-wrapper
    systemd
    libfprint
  ] ++ checkInputs;

  checkInputs = with python3.pkgs; [
    gobject-introspection # for setup hook
    python-dbusmock
    dbus-python
    pygobject3
    pycairo
    pypamtest
    gusb # Required by libfprint’s typelib
  ];

  mesonFlags = [
    "-Dgtk_doc=true"
    "-Dpam_modules_dir=${placeholder "out"}/lib/security"
    "-Dsysconfdir=${placeholder "out"}/etc"
    "-Ddbus_service_dir=${placeholder "out"}/share/dbus-1/system-services"
    "-Dsystemd_system_unit_dir=${placeholder "out"}/lib/systemd/system"
  ];

  PKG_CONFIG_DBUS_1_INTERFACES_DIR = "${placeholder "out"}/share/dbus-1/interfaces";
  PKG_CONFIG_POLKIT_GOBJECT_1_POLICYDIR = "${placeholder "out"}/share/polkit-1/actions";
  PKG_CONFIG_DBUS_1_DATADIR = "${placeholder "out"}/share";

  # FIXME: Ugly hack for tests to find libpam_wrapper.so
  LIBRARY_PATH = lib.makeLibraryPath [ python3.pkgs.pypamtest ];

  doCheck = false;

  postPatch = ''
    patchShebangs \
      po/check-translations.sh \
      tests/unittest_inspector.py
  '';

  meta = with lib; {
    homepage = "https://fprint.freedesktop.org/";
    description = "D-Bus daemon that offers libfprint functionality over the D-Bus interprocess communication bus";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ abbradar elyhaka ];
  };

}
