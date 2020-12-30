{ my, mfunc, pkgs, mpkgs, ... }:
{

  # Games
  home.packages = with pkgs; [

    # Emulators
    mednafen
    mednaffe
    retroarch

    # Proper games
    zeroad
    chocolateDoom
    crispyDoom
    xonotic
    mpkgs.srb2

  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc

    # FPS
    openarena

    # N64
    mupen64plus
    wxmupen64plus

  ] [];

}
