{ my, mfunc, pkgs, mpkgs, ... }:
{

  # Games
  home.packages = with pkgs; [

    # Emulators
    pcsxr
    pcsx2
    citra
    desmume
    mednafen
    mednaffe
    dolphinEmu

    # Retroarch
    (retroarch.override { cores = with libretro; [
      mgba
      snes9x
      fceumm
      mupen64plus
    ]; })

    # Proper games
    zeroad
    openttd
    xonotic
    hedgewars
    teeworlds
    assaultcube
    crispy-doom
    space-cadet-pinball
    mpkgs.srb2
    mpkgs.srb2kart

    # Steam
    steam

    # Simulator
    flightgear

    # Gnome
    gnome.aisleriot
    gnome.gnome-mines
    gnome.gnome-sudoku
    gnome.gnome-chess

  ] ++
  # amd64 only games
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # Minecraft
    minecraft
    prismlauncher

    # FPS
    openarena

    # N64
    mupen64plus

  ] [];

}
