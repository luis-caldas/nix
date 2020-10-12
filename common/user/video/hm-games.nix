{ my, mfunc, pkgs, upkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  # Games
  home.packages = with pkgs; [

    # Emulators
    upkgs.mednafen
    mednaffe
    retroarch

  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc

    # N64
    mupen64plus

  ] [];

}
