{ my, mfunc, pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  # Games
  home.packages = with pkgs; [

    # Emulators
    mednafen
    mednaffe

  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Minecraft
    multimc

    # N64
    mupen64plus

  ] [];

}
