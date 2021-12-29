{ stdenv
, makeDesktopItem
, srb2-unwrapped
, srb2
}:
let

  # Create binary name so we can reference it on the desktop link
  gameBinName = "${srb2-unwrapped.pname}";

  # Agree on a common icon name
  iconName = "icon.png";

  # Add icon to the store
  iconFile = stdenv.mkDerivation rec {
    name = "${gameBinName}-icon";
    iconSrc = ./. + ("/" + iconName);
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p "$out"
      cp ${iconSrc} "$out/${iconName}"
    '';
  };

  # Create the full desktop link
  desktopLink = makeDesktopItem {
    name = "srb2";
    exec = gameBinName;
    icon = "${iconFile}/${iconName}";
    comment = "Sonic Robo Blast 2 Kart fangame";
    desktopName = "Sonic Robo Blast 2";
    genericName = "Sonic Robo Blast 2";
    categories = "Game;";
  };

in
stdenv.mkDerivation rec {

  name = iconFile.name;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/applications
    ln -s ${desktopLink}/share/applications/* $out/share/applications
  '';

}

