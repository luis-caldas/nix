{ cmake
, libGL, freeglut
, xorg
, alsaLib
, portaudio
, libsndfile
}:

stdenv.mkDerivation rec {

  pname = "bc";
  version = "release561";

  src = fetchFromGitHub {
    owner = "bridgecommand";
    repo = pname;
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
    ln -s $out/lib/bridgecommand $out/bin/bridgecommand
  '';

}
