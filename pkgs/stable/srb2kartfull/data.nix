{ stdenv, lib
, p7zip
, fetchurl
, srb2-unwrapped
, unzip
}:

stdenv.mkDerivation rec {

  pname = "srb2-data";
  inherit (srb2-unwrapped) owner repo version fixVersion;

  nativeBuildInputs = [ unzip ];
  buildInputs = [ unzip ];

  src = fetchurl {
    url = "https://github.com/${owner}/${repo}/releases/download/v${version}/srb2kart-v${fixVersion}-Installer.exe";
    sha256 = "0bk36y7wf6xfdg6j0b8qvk8671hagikzdp5nlfqg478zrj0qf6cs";
  };

  unpackPhase = ''
    "${p7zip}/bin/7z" -y x "''${src}"
  '';

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/srb2
    cp -r mdls/ *.kart *.dat *.pdf *.srb $out/share/srb2/
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame -- data files";
    homepage = "https://www.srb2.org/";
    platforms = platforms.linux;
    hydraPlatforms = [];
  };

}
