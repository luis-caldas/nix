{ lib, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, libevdev
, systemd
, libconfig
, udev
}:

stdenv.mkDerivation rec {

  pname = "logiops";
  version = "0.2.3";
  outputs = [ "out" "devdoc" ];

  src = fetchFromGitHub {
    owner = "PixlOne";
    repo = pname;
    rev = "v${version}";
    sha256 = "1wgv6m1kkxl0hppy8vmcj1237mr26ckfkaqznj1n6cy82vrgdznn";
  };

  configurePhase = ''
    mkdir build
    cd build
    cmake ..
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    libevdev
    systemd
    libconfig
    udev
  ];

  doCheck = true;

  meta = with lib; {
    platforms = platforms.linux;
  };

}
