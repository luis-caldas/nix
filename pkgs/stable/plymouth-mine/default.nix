{ stdenv
, python3
, courier-prime
, imagemagick
, reference
}:

defaultTheme: font: logoText:

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
      -font "${font}" \
      -gravity center \
      caption:"${logoText}" \
      -gravity Center \
      -composite -strip \
      logo.png

    # Password text insertion
    magick \
      assets/extra/box.png \
      -alpha set \
      \( \
        -background none \
        -fill white \
        -font "${font}" \
        -pointsize 16 \
        label:"PASSWORD" \
        +repage \
        -gravity center \
        -background none \
        -extent "%[fx:w+10]x%[fx:h+10]" \
        +repage \
        -write mpr:txt \
        +delete \
      \) \( \
        mpr:txt \
        -background white \
        -alpha remove \
        -alpha off \
        +repage \
      \) \
        -gravity northwest \
        -geometry +60+%[fx:30-h/2] \
        -compose Dst_Out \
        -composite \
      mpr:txt \
        -gravity northwest \
        -geometry +60+%[fx:32-h/2] \
        -compose Over \
        -composite \
        assets/extra/box.patched.png

    # Overwrite
    mv -f assets/extra/box.patched.png assets/extra/box.png

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