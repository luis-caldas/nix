{ pkgs, ... }:
let
  my = import ../../../config.nix;
in
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
    openbox
    conky
    rofi

    # Functional autism
    haskellPackages.xmonad
    haskellPackages.xmobar
    haskellPackages.xmonad-entryhelper

    # Testing
    glxinfo
 
    # Video player
    mpv

  ] ++ my.config.packages.user.video;

}
