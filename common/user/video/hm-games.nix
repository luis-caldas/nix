{ my, mfunc, pkgs, mpkgs, upkgs, ... }:
{

  # Games
  home.packages = with pkgs; [

    # Emulators
    # pcsxr  # Uses unsafe ffmpeg
    pcsx2
    desmume
    mednafen
    mednaffe
    retroarch
    dolphinEmu
    upkgs.citra

    # Proper games
    zeroad
    chocolateDoom
    crispyDoom
    xonotic
    mpkgs.srb2

    # Steam
    upkgs.steam

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

  # Enable retroarch cores
  nixpkgs.config.retroarch = {
    enableFceumm = true;
    enableSnes9x = true;
    enableMgba = true;
    enableMupen64Plus = true;
  };

}
