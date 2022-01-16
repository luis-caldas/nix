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
  pname = "sonic-robo-blast-2";
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
  repo = "SRB2";
  version = "2.2.9";
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
    mkdir -p $out/bin $out/share
    cp srb2.png $out/share/${pname}-icon.png
    cp bin/Linux*/Release/lsdl2srb2 $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame";
    homepage = "https://www.srb2.org/";
    platforms = allowedPlatforms;
    license = licenses.gpl2;
  };

}

