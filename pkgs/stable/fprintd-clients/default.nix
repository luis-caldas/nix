{ lib, stdenv
, fetchFromGitLab
, pkg-config
, libfprint
, polkit
, dbus
, dbus-glib
, linux-pam
, libpam-wrapper
, meson
, python3
, python3Packages
, perl
, ninja
, gusb
, pixman
, glib
, nss
, gobject-introspection
, coreutils
, gtk-doc
, docbook-xsl-nons
, docbook_xml_dtd_43
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
    python3Packages.pycairo
    python3Packages.dbus-python
    python3Packages.python-dbusmock
    python3Packages.pygobject3
    python3Packages.pypamtest
    meson
    libfprint
    polkit
    dbus
    dbus-glib
    linux-pam
    libpam-wrapper
    perl
    ninja
    gtk-doc
    docbook-xsl-nons
    docbook_xml_dtd_43
    gobject-introspection
  ];

  buildInputs = [
    gusb
    pixman
    glib
    nss
  ];

  checkInputs = [
    python3
  ];

  mesonFlags = [
    "-Dudev_rules_dir=${placeholder "out"}/lib/udev/rules.d"
    # Include virtual drivers for fprintd tests
    "-Ddrivers=all"
  ];

  doCheck = true;

  postPatch = ''
    patchShebangs \
      po/check-translations.sh \
      tests/test-runner.sh \
      tests/unittest_inspector.py \
      tests/virtual-image.py
  '';

  meta = with lib; {
    homepage = "https://gitlab.freedesktop.org/uunicorn/fprintd";
    description = "D-Bus service to access fingerprint readers";
    platforms = platforms.linux;
  };
}
