{ stdenv
, lib
, gcc, curl, pkg-config
, nasm
, libpng, libupnp, zlib, libgme, openmpt123
, SDL2, SDL2_mixer
, fetchFromGitHub
}:

stdenv.mkDerivation rec {

  # Create name and fix it
  pname = "sonic-robo-blast-2-kart";
  goodName = let
    capitalizeFirst = stringIn: let
      strInLen = builtins.stringLength stringIn;
    in
      if (builtins.stringLength stringIn) >= 1 then
        (lib.toUpper (builtins.substring 0 1 stringIn)) +
        (builtins.substring 1 strInLen stringIn)
      else
        stringIn;
    wordList = lib.splitString "-" pname;
    firstUpperList = map capitalizeFirst wordList;
  in
    lib.concatStringsSep " " firstUpperList;

  # Owner and repo info
  owner = "STJr";
  repo = "Kart-Public";
  version = "1.3";
  fixVersion = builtins.replaceStrings ["."] [""] version;

  # Check system compatibility
  allowedPlatforms = with lib; intersectLists platforms.x86 platforms.linux;
  systemChosen = let
    amd64Prefix = "x86_64";
  in if builtins.elem stdenv.system allowedPlatforms
    then if (lib.hasPrefix amd64Prefix stdenv.system) then
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
    mkdir -p $out/bin $out/share
    cp srb2.png $out/share/${pname}-icon.png
    cp bin/Linux*/Release/lsdl2srb2kart $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 Kart is a kart racing fangame with Sonic and SEGA-themed characters, items and maps";
    homepage = "https://mb.srb2.org/threads/srb2kart.25868/";
    platforms = allowedPlatforms;
    license = licenses.gpl2;
  };

}

