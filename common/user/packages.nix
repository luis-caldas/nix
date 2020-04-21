{ pkgs, ... }:
{

  home.packages = with pkgs; [
    # Basic tools that I use

    ## Dev
    
    # Shell
    shellcheck

    # Haskell
    haskellPackages.xmonad-entryhelper

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
  ];

}
