{ stdenv, lib
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
    url = "https://github.com/${owner}/${repo}/releases/download/${repo}_release_${version}/${repo}-v${fixVersion}-Full.zip";
    sha256 = "0zgkwvmqdzjdaf6g2w5ss0c02b84yji27vqjdg7bb0gd9dh49rj8";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/srb2
    cp -r *pk3 *dta *dat models/ $out/share/srb2/
  '';

  meta = with lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame -- data files";
    homepage = "https://www.srb2.org/";
    platforms = platforms.linux;
    hydraPlatforms = [];
  };

}
