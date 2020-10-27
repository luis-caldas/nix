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
    zeroad
    mpkgs.srb2full.srb2

  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc

    # N64
    mupen64plus
    wxmupen64plus

  ] [];

}
