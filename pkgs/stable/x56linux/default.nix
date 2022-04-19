{ lib
, stdenv
, pkgconfig
, libusb1
, fetchFromGitHub
}:

stdenv.mkDerivation rec {

  pname = "x56linux";
  owner = "Chryseus";
  version = "master";

  src = fetchFromGitHub {
    owner = owner;
    repo = pname;
    rev = version;
    sha256 = "0sxl2yhzz8y9bm8xmxxn7cqmpv45dn8kf6fnh389s35rsl580mw3";
  };

  buildInputs = [
    pkgconfig
    libusb1
  ];

  installPhase = ''
    mkdir -p $out/bin
    mv src/x56 $out/bin/x56linux
  '';

  meta = with lib; {
    description = "Saitek HOTAS X56 Configuration Utillity";
    homepage = "https://github.com/Chryseus/x56linux";
    platforms = platforms.linux;
  };

}