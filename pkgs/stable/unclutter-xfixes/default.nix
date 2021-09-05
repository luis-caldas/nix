{ lib, stdenv, fetchFromGitHub,
  xorg, libev,
  pkg-config, asciidoc, libxslt, docbook_xsl }:

stdenv.mkDerivation rec {
  pname = "unclutter-xfixes";
  version = "1.6";

  src = fetchFromGitHub {
    owner = "Airblader";
    repo = "unclutter-xfixes";
    rev = "v${version}";
    sha256 = "1mqir7imiiyl7vrnnnid80kb14fh78acrkffcm3z1l3ah9madqmj";
  };

  nativeBuildInputs = [ pkg-config asciidoc libxslt docbook_xsl ];
  buildInputs = [ xorg.xlibsWrapper libev xorg.libXi xorg.libXfixes ];

  makeFlags = [ "CC=${stdenv.cc.targetPrefix}cc" ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "Rewrite of unclutter using the X11 Xfixes extension";
    platforms = platforms.unix;
    license = lib.licenses.mit;
    inherit version;
    maintainers = [ maintainers.globin ];
  };
}
