{ pkgs, ... }:
let
  my = import ../../config.nix;
in
{

  home.packages = with pkgs; [
    # Basic tools that I use that are non graphical

    ## Dev
    
    # Shell
    shellcheck

    # C
    gcc
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
  ] ++ my.config.packages.user.normal;

}
