{ my, mfunc, pkgs, mpkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

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
    mpkgs.srb2

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
