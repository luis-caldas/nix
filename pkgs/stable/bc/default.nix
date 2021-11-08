{ stdenv, lib
, cmake
, libGL, freeglut
, xorg
, alsaLib
, portaudio
, libsndfile
, fetchFromGitHub
}:

stdenv.mkDerivation rec {

  pname = "bridgecommand";
  version = "release561";

  src = fetchFromGitHub {
    owner = "bridgecommand";
    repo = "bc";
    rev = version;
    sha256 = "10sgz1aq5hgz5brkhgisffrz7p3iwb5afvd2d54bj6j4l06x4xbx";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    libGL
    freeglut
    xorg.libX11
    xorg.libXext
    xorg.libXxf86vm
    xorg.libXcursor
    alsaLib
    portaudio
    libsndfile
  ];

  configurePhase = ''
    cd bin
    cmake ../src
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv ../bin $out/lib
    cat > $out/bin/bridgecommand <<EOF
      #!/usr/bin/env sh
      cd "$out"/lib
      ./bridgecommand
    EOF
  '';

  meta = with lib; {
    description = "Bridge Command is a free interactive ship simulator program";
    homepage = "https://www.bridgecommand.co.uk/";
  };

}
