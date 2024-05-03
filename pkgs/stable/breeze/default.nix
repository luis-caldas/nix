{ stdenv
, inkscape
, xorg
, reference
, colours ? {
    accent = "#a0a0a0";
    base = "#000000";
    border = "#000000";
    logo = "#d0d0d0";
  }
}:
let

  # Build output folder
  outputFolder = "out";

in
stdenv.mkDerivation rec {

  pname = "breeze-hacked";
  version = "0.0.1";

  src = reference.projects.breeze-hacked;

  nativeBuildInputs = [
    inkscape
    xorg.xcursorgen
  ];

  buildPhase = ''
    # Recolour it
    bash recolor-cursor.sh \
        --accent-color "${colours.accent}" \
        --base-color "${colours.base}" \
        --border-color "${colours.border}" \
        --logo-color "${colours.logo}"
    # Build it
    bash build.sh
  '';

  installPhase = ''
    # Create output folder
    output_cursors="$out/share/icons"
    mkdir -p "$output_cursors"
    # Copy it over
    cp -a "${outputFolder}"/* "$output_cursors"/.
  '';

}