{ lib
, stdenv
, python3
, fetchPypi
, python3Packages
, papirus-icon-theme
, fetchFromGitHub
}:
let

  # Needed Package
  basicColormath = python3Packages.buildPythonPackage rec {

    # Info
    pname = "basic_colormath";
    version = "0.5.0";

    # Source
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-p/uNuNg5kqKIkeMmX5sWY8umGAg0E4/otgQxhzIuo0E=";
    };

    # Inputs
    buildInputs = [
      (python3.withPackages (packages: with packages; [
        setuptools
        setuptools-scm
      ]))
    ];

    # Type
    format = "pyproject";

    # Check
    doCheck = false;

  };

in stdenv.mkDerivation rec {

  pname = "poorpirus";
  version = "0.1";

  colour = [0 0 0.05];

  src = fetchFromGitHub {
    owner = "NicklasVraa";
    repo = "Color-manager";
    rev = "9e55e0971ecd0e3141ed5d7d9a8377f7052cef96";
    sha256 = "sha256-kXRjp1sFgSiIQC9+fUQcNRK990Hd5nZwJpRGB7qRYrY=";
  };

  buildInputs = [
    (python3.withPackages (packages: with packages; [
      tqdm
      pillow
      basicColormath
    ]))
  ];

  nativeBuildInputs = [
    papirus-icon-theme
  ];

  postUnpack = ''
    # Path
    mkdir extracted
    cp -r "${papirus-icon-theme}/share/icons/Papirus" extracted/.
    cp -r "${papirus-icon-theme}/share/icons/Papirus-Dark" extracted/.
    cp -r "${papirus-icon-theme}/share/icons/Papirus-Light" extracted/.

    # Permissions
    find extracted -type d -exec chmod 700 {} \;
    find extracted -type f -exec chmod 600 {} \;
  '';

  buildPhase = ''
    # Create Output
    mkdir output

    # Build it
    python - <<EOF

    from color_manager import utils

    utils.recolor(
      "../extracted/Papirus",
      "./output",
      "Poorpirus",
      (${lib.strings.concatStringsSep ", " (map builtins.toString colour)})
    )
    utils.recolor(
      "../extracted/Papirus-Dark",
      "./output",
      "Poorpirus-Dark",
      (${lib.strings.concatStringsSep ", " (map builtins.toString colour)})
    )
    utils.recolor(
      "../extracted/Papirus-Light",
      "./output",
      "Poorpirus-Light",
      (${lib.strings.concatStringsSep ", " (map builtins.toString colour)})
    )

    EOF
  '';

  installPhase = ''

    # Create Package Output
    tip="$out/share/icons"
    mkdir -p "$tip"

    # Fix Links
    for file in output/*/*; do
      if [ -h "$file" ]; then
        link="$(readlink "$file")"
        new_link="''${link/Papirus/Poorpirus}"
        unlink "$file"
        ln -s "$new_link" "$file"
      fi
    done

    # Copy Over Everything
    cp -r output/* "$tip/."

  '';

  patchShebangs = false;

  meta = with lib; {
    description = "Monochrome Papirus";
    platforms = platforms.linux;
  };

}