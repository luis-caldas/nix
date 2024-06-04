{ stdenv
, python3
, reference
}:

defaultTheme:

stdenv.mkDerivation rec {

  pname = defaultTheme;
  version = "0.0.1";

  src = reference.projects.bootanim;

  nativeBuildInputs = [
    (python3.withPackages (packages: with packages; [ wand ]))
  ];

  buildPhase = ''
    # Compile the theme
    python scaler.py plymouth
  '';

  installPhase = ''
    # Create the output folder
    mkdir -p $out/share/plymouth/themes/
    # Copy everything
    cp -r dist/plymouth $out/share/plymouth/themes/${defaultTheme}
    # Fix the paths
    sed -i "s!/usr/!$out/!g" $out/share/plymouth/themes/${defaultTheme}/${defaultTheme}.plymouth
  '';

}