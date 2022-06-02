{ my, mfunc, pkgs, mpkgs, ... }:
{

  # Games
  home.packages = with pkgs; [

    # Emulators
    # pcsxr  # Uses unsafe ffmpeg
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
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc
    minecraft

    # FPS
    openarena

    # N64
    mupen64plus
    wxmupen64plus

  ] [];

}
