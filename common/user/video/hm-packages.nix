{ pkgs, ... }:
let
  configgo = import ../../../config.nix;
in
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
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

  ] ++ configgo.packages.user.video;

}
