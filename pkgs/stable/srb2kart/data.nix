{ stdenv, lib
, unar
, fetchurl
, srb2kart-unwrapped
, unzip
}:

stdenv.mkDerivation rec {

  pname = "${srb2kart-unwrapped.pname}-data";
  inherit (srb2kart-unwrapped) owner repo version fixVersion;

  nativeBuildInputs = [ unzip ];

  src = fetchurl {
    url = "https://github.com/${owner}/${repo}/releases/download/v${version}/srb2kart-v${fixVersion}-Installer.exe";
    sha256 = "sha256-Gz2Gqlmd4R5Y1qhZXhFeiWqJ7xjbkKeDu8D38lA/xT8=";
  };

  unpackPhase = ''
    "${unar}/bin/unar" -D "''${src}"
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
