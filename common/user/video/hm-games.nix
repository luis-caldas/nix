{ my, mfunc, pkgs, mpkgs, upkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  # Games
  home.packages = with pkgs; [

    # Emulators
    upkgs.mednafen
    mednaffe
    retroarch

    # Proper games
    #{ "0ad" }@args: args."0ad"
    #upkgs.sm64ex

  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc

    # Sonic Robo Blast 2
    mpkgs.srb2full.srb2

    # N64
    mupen64plus
    wxmupen64plus

  ] [];

}
