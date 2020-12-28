{ stdenv
, gcc, curl, pkg-config
, nasm
, libpng, libupnp, zlib, libgme, openmpt123
, SDL2, SDL2_mixer
}:

stdenv.mkDerivation rec {

  pname = "sonic-robo-blast-2";
  version = "2.2.8";

  amd64linux = "x86_64-linux";
  allowedPlatforms = [ amd64linux "i686-linux" ];

  # Check system compatibility
  systemChosen =
  if builtins.elem stdenv.system allowedPlatforms
    then if (stdenv.system == amd64linux) then
      "LINUX64"
    else
      "LINUX"
  else
    throw ("Unsupported system " + stdenv.system);

  src = builtins.fetchGit {
    url = "https://github.com/STJr/SRB2";
    ref = "SRB2_release_${version}";
  };

  buildInputs = [

    gcc
    curl
    pkg-config

    nasm

    libpng
    libupnp
    zlib
    libgme
    openmpt123

    SDL2
    SDL2_mixer

  ];

  patchPhase = ''
    sed 's/-DCOMPVERSION//' -i src/Makefile
    sed 's/illegal/NixOS/' -i src/comptime.c
  '';

  buildPhase = ''
    make -C src/ ${systemChosen}=1
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv bin/Linux64/Release/lsdl2srb2 $out/bin/srb2
    strip $out/bin/srb2
  '';

  meta = with stdenv.lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame";
    homepage = "https://www.srb2.org/";
    platforms = allowedPlatforms;
    hydraPlatforms = [];
  };

}

