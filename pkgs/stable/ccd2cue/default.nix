{ lib
, stdenv
, automake
, autoconf
, gettext
, help2man
, texinfo
}:

stdenv.mkDerivation rec {

  pname = "ccd2cue";
  version = "0.5";

  src = fetchGit {
    url = "git://git.savannah.gnu.org/${pname}";
    ref = "refs/tags/${version}";
    rev = "1c78c36c7d220c8ce1ad5d91f14e8cc00995bda7";
  };

  nativeBuildInputs = [
    automake
    autoconf
    gettext
    help2man
    texinfo
  ];

  configurePhase = ''
    ./bootstrap
    mkdir "$out"
    ./configure --prefix="$out"
  '';

  meta = with lib; {
    description = "CCD sheet to CUE sheet converter";
    homepage = "https://www.gnu.org/software/ccd2cue/";
    license = with licenses; [ gpl3Plus fdl13Plus ];
    platforms = platforms.linux;
  };

}
