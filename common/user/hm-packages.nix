{ pkgs, ... }:
let
  configgo = import ../../config.nix;
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
  ] ++ configgo.packages.user.normal;

}
