{ pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  # Games
  home.packages = with pkgs; [

    # Minecraft
    multimc

    # Emulators
    mednafen
    mednaffe
    mupen64plus

    # Dwarf Fortress
    dwarf-fortress

  ];

}
