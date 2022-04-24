{ lib
, stdenv
, fetchFromGitHub
, cmake, gnumake, pkg-config
, libsForQt5
, opencv4, procps
, makeDesktopItem, fetchurl
}:
stdenv.mkDerivation rec {

  pname = "opentrack";
  version = "2022.1.1";

  src = fetchFromGitHub {
    owner = "opentrack";
    repo = "opentrack";
    rev = "opentrack-${version}";
    sha256 = "01mcxdzk99dxl192mxmlvscf16wkrrngk9v9sbr1qf5sbqbvhljk";
  };

  nativeBuildInputs = [ cmake gnumake pkg-config libsForQt5.wrapQtAppsHook ];
  buildInputs = [ libsForQt5.qt5.qtbase libsForQt5.qt5.qttools opencv4 procps ];

  dontWrapQtApps = true;
  preFixup = ''
      wrapQtApp "$out/bin/opentrack"
  '';

  desktopItems = [
    (makeDesktopItem rec {
      name = "opentrack";
      exec = "opentrack";
      icon = fetchurl {
        url = "https://github.com/opentrack/opentrack/raw/opentrack-${version}/gui/images/opentrack.png";
        sha256 = "0d114zk78f7nnrk89mz4gqn7yk3k71riikdn29w6sx99h57f6kgn";
      };
      desktopName = name;
      genericName = "Head tracking software";
      categories = "Utility;";
    })
  ];

  meta = with lib; {
    homepage = "https://github.com/opentrack/opentrack";
    description = "Head tracking software for MS Windows, Linux, and Apple OSX";
    license = licenses.isc;
    maintainers = with maintainers; [ zaninime ];
  };

}