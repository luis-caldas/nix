{ lib, stdenv
, fetchFromGitLab
, pkg-config
, meson
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
    meson
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

  mesonFlags = [
    "-Dudev_rules_dir=${placeholder "out"}/lib/udev/rules.d"
  ];
  
  meta = with lib; {
    homepage = "https://gitlab.freedesktop.org/uunicorn/fprintd";
    description = "D-Bus service to access fingerprint readers";
    platforms = platforms.linux;
  };
}
