{ stdenv
, makeDesktopItem
, srb2kart-unwrapped
}:
let

  # Create the full desktop link
  desktopLink = makeDesktopItem rec {
    name = "${srb2kart-unwrapped.pname}-link";
    exec = srb2kart-unwrapped.pname;
    icon = "${srb2kart-unwrapped}/share/${srb2kart-unwrapped.pname}-icon.png";
    comment = srb2kart-unwrapped.meta.description;
    desktopName = srb2kart-unwrapped.goodName;
    genericName = desktopName;
    categories = "Game;";
  };

in
stdenv.mkDerivation rec {

  name = desktopLink.name;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/applications
    ln -s ${desktopLink}/share/applications/* $out/share/applications
  '';

}

