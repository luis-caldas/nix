{ stdenv
, makeDesktopItem
, srb2-unwrapped
}:
let

  # Create the full desktop link
  desktopLink = makeDesktopItem rec {
    name = "${srb2-unwrapped.pname}-link";
    exec = srb2-unwrapped.pname;
    icon = "${srb2-unwrapped}/share/${srb2-unwrapped.pname}-icon.png";
    comment = srb2-unwrapped.meta.description;
    desktopName = srb2-unwrapped.goodName;
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

