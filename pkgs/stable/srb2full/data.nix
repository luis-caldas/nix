{ stdenv, fetchurl, srb2-unwrapped, unzip }:

stdenv.mkDerivation rec {

  pname = "srb2-data";
  inherit (srb2-unwrapped) version;

  nativeBuildInputs = [ unzip ];
  buildInputs = [ unzip ];

  src = fetchurl {
    #url = "https://github.com/STJr/SRB2/releases/download/SRB2_release_${version}/SRB2-v${version}-Full.zip";
    url = "https://files.srb2skybase.org/srb2_v2.2/SRB2-v${version}-Full.zip";
    sha256 = "066p2k0ysl97kkf8pm4p8hrrw9i7b7if77ra8fv2vm3v2aqhaf3s";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/srb2
    cp -r *pk3 *dta *dat models/ $out/share/srb2/
  '';

  meta = with stdenv.lib; {
    description = "Sonic Robo Blast 2 is a 3D open-source Sonic the Hedgehog fangame -- data files";
    homepage = "https://www.srb2.org/";
    platforms = platforms.linux;
    hydraPlatforms = [];
  };

}
