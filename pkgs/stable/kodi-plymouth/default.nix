{ stdenv
, git
, fetchFromGitHub
}:
stdenv.mkDerivation rec {
  pname = "kodi-plymouth";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "solbero";
    repo = "plymouth-theme-kodi-animated-logo";
    rev = "f16d51632ef5d0182821749901af04bbe2efdfd6";
    sha256 = "07wlyqqihhvhfv7qy0x2khi2r6fbsvfrhpdbjjfz4ljpvn76pf23";
  };

  phases = [ "unpackPhase" "configurePhase" "installPhase" ];

  buildInputs = [
    git
  ];

  configurePhase = ''
    mkdir -p $out/share/plymouth/themes/
  '';

  installPhase = ''
    cp -r plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo $out/share/plymouth/themes/kodi-plymouth
    cat plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo/kodi-animated-logo.plymouth | sed  "s@\/usr\/@$out\/@" > $out/share/plymouth/themes/kodi-plymouth/kodi-plymouth.plymouth
    rm plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo/kodi-animated-logo.plymouth
  '';

}