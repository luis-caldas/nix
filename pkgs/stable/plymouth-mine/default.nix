{ stdenv
, python3
, roboto
, imagemagick
, reference
}:

defaultTheme: logoText:

stdenv.mkDerivation rec {

  pname = defaultTheme;
  version = "0.0.1";

  src = reference.projects.bootanim;

  nativeBuildInputs = [

    # Image
    imagemagick

    # Packages
    (python3.withPackages (packages: with packages; [ wand ]))

  ];

  buildPhase = ''

    # Create the logo
    magick \
      -size 1024x1024 xc:transparent \
      -fill white \
      -background None \
      -font ${roboto}/share/fonts/truetype/Roboto-Bold.ttf \
      -gravity center \
      caption:"${logoText}" \
      -gravity Center \
      -composite -strip \
      logo.png

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