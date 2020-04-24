{ pkgs, ... }:
let
  my = import ../../../config.nix;
in
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
    openbox
    compton
    conky
    rofi

    # Functional
    haskellPackages.xmobar

    # Image editing
    gimp
    inkscape

    # Testing
    glxinfo
 
    # Video player
    mpv

  ] ++ my.config.packages.user.video;

}
