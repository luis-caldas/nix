{ stdenv, lib
, p7zip
, fetchurl
, srb2kart-unwrapped
, unzip
}:

stdenv.mkDerivation rec {

  pname = "${srb2kart-unwrapped.pname}-data";
  inherit (srb2kart-unwrapped) owner repo version fixVersion;

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
    mkdir -p $out/share/srb2kart
    cp -r mdls/ *.kart *.dat *.pdf *.srb $out/share/srb2kart/
  '';

  meta = srb2kart-unwrapped.meta // {
    description = srb2kart-unwrapped.meta.description + " -- data files";
  };

}
