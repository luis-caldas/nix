{ stdenv, lib, fetchgit, cmake, SDL2, qt5, boost }:

stdenv.mkDerivation {
  pname = "citra";
  version = "2020-12-07";

  # Submodules
  src = fetchgit {
    url = "https://github.com/citra-emu/citra";
    rev = "3f13e1cc2419fac837952c44d7be9db78b054a2f";
    sha256 = "1bbg8cwrgncmcavqpj3yp4dbfkip1i491krp6dcpgvsd5yfr7f0v";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ SDL2 qt5.qtbase qt5.qtmultimedia boost qt5.wrapQtAppsHook ];

  preConfigure = ''
    # Trick configure system.
    sed -n 's,^ *path = \(.*\),\1,p' .gitmodules | while read path; do
      mkdir "$path/.git"
    done
  '';

  meta = with lib; {
    homepage = "https://citra-emu.org";
    description = "An open-source emulator for the Nintendo 3DS";
    license = licenses.gpl2;
    maintainers = with maintainers; [ abbradar ];
    platforms = platforms.linux;
  };
}