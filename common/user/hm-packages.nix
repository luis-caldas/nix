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

    ##

    # System
    htop

    # Network 
    nmap

    # Fetching packages
    neofetch
    screenfetch
  ] ++ my.config.packages.user.normal;

}
