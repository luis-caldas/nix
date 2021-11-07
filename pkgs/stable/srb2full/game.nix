{ stdenv
, lib
, gcc, curl, pkg-config
, nasm
, libpng, libupnp, zlib, libgme, openmpt123
, SDL2, SDL2_mixer
, fetchFromGitHub
}:

stdenv.mkDerivation rec {

  pname = "sonic-robo-blast-2";
  owner = "STJr";
  repo = "SRB2";
  version = "2.2.9";
  fixVersion = builtins.replaceStrings ["."] [""] version;

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

  src = fetchFromGitHub {
    owner = owner;
    repo = repo;
    rev = "${repo}_release_${version}";
    sha256 = "07wlyqqihhvhfv7qy0x2khi2r6fbsvfrhpdbjjfz3ljpvn76pf23";
  };

  nativeBuildInputs = [ gcc curl pkg-config ];
  buildInputs = [
    nasm
    libpng libupnp zlib libgme openmpt123
    SDL2 SDL2_mixer
  ];

  patches = [ ./makefile-endef-fix.patch ];

  postPatch = ''
    sed 's/-DCOMPVERSION//' -i src/Makefile
    sed 's/illegal/NixOS/' -i src/comptime.c
  '';

  buildPhase = ''
    make -C src/ ${systemChosen}=1
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv bin/Linux*/Release/lsdl2srb2 $out/bin/sonic-robo-blast-2
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame";
    homepage = "https://www.srb2.org/";
    platforms = allowedPlatforms;
    hydraPlatforms = [];
  };

}

