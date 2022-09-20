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
    # hedgewars
    teeworlds
    assaultcube
    crispyDoom
    chocolateDoom
    mpkgs.srb2
    mpkgs.srb2kart

    # Steam
    steam

    # Simulator
    flightgear

  ] ++
  # amd64 only games
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # Minecraft
    polymc
    minecraft

    # FPS
    openarena

    # N64
    mupen64plus

  ] [];

}
