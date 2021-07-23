{ lib, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {

  version = "0.0.1";
  pname = "iso2opl";
  outputs = [ "out" ];

  src = fetchFromGitHub {
    owner = "arcadenea";
    repo = pname;
    rev = "master";
    sha256 = "1fvfxnf8k3kay6q9pnvkp39x0f6xbhibp6sy7zw1y60my8brg77j";
  };
 
  installPhase = ''
    mkdir -p "$out/bin"
    mv "iso2opl" "$out/bin/iso2opl"
  '';

  meta = with lib; {
    platforms = platforms.linux;
  };

}
