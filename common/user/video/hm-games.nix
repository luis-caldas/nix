{ my, mfunc, pkgs, mpkgs, ... }:
{

  # Games
  home.packages = with pkgs; [

    # Emulators
    # pcsxr  # Uses unsafe ffmpeg
    # pcsx2  # Needs to compile
    desmume
    mednafen
    mednaffe
    retroarch

    # Proper games
    zeroad
    chocolateDoom
    crispyDoom
    xonotic
    mpkgs.srb2

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
