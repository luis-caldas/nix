{ stdenv
, lib
, gcc, curl, pkg-config
, nasm
, libpng, libupnp, zlib, libgme, openmpt123
, SDL2, SDL2_mixer
, fetchFromGitHub
}:
stdenv.mkDerivation rec {

  pname = "sonic-robo-blast-2-kart";
  owner = "STJr";
  repo = "Kart-Public";
  version = "1.3";
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
    rev = "v${version}";
    sha256 = "131g9bmc9ihvz0klsc3yzd0pnkhx3mz1vzm8y7nrrsgdz5278y49";
  };

  nativeBuildInputs = [ gcc curl pkg-config ];
  buildInputs = [
    nasm
    libpng libupnp zlib libgme openmpt123
    SDL2 SDL2_mixer
  ];

  postPatch = ''
    sed 's/-DCOMPVERSION//' -i src/Makefile
    sed 's/illegal/NixOS/' -i src/comptime.c
  '';

  buildPhase = ''
    make -C src/ ${systemChosen}=1
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv bin/Linux*/Release/lsdl2srb2kart $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 Kart is a kart racing fangame with Sonic and SEGA-themed characters, items and maps";
    homepage = "https://mb.srb2.org/threads/srb2kart.25868/";
    platforms = platforms.linux;
  };

}

