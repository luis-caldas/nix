{ pkgs, ... }:
let
  my = import ../../config.nix;
  mfunc = import ../../functions/func.nix;
in
{

  home.packages = with pkgs; [
    # Basic tools that I use that are non graphical

    ## Dev
    
    # Shell
    shellcheck

    # C
    gcc
    cmake
    gnumake

    # Haskell
    ghc

    # JSON
    jq

    ##

    # User tools
    mutt
    irssi

    # Image viewer
    jp2a

    # Fetching packages
    neofetch
    screenfetch
  ] ++ mfunc.useDefault my.config.audio [ ncspot playerctl ] [] 
  ++ my.config.packages.user.normal;

}
