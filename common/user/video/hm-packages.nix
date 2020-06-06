{ pkgs, ... }:
let
  my = import ../../../config.nix;
  mfunc = import ../../../functions/func.nix;
in
{

  nixpkgs.config.allowUnsupportedSystem = true;

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
    openbox
    picom
    conky
    rofi

    # XDG
    dconf
    gnome-themes-extra

    # File manager
    gnome3.nautilus

    # Desktop lock
    xss-lock

    # Electronics
    kicad
    logisim

    # Key reassignment
    xorg.xev

    # Functional
    haskellPackages.xmobar

    # Web
    firefox
    electron

    # Calculator
    gnome3.gnome-calculator

    # Image editing
    gimp
    inkscape

    # Image viewer
    sxiv

    # Email
    thunderbird

    # Wallpaper
    nitrogen

    # Voip
    mumble

    # Testing
    glxinfo

    # Video player
    mpv

    # Casting
    catt

    # Screeshot
    scrot

  ] ++
  mfunc.useDefault my.config.x86_64 [ obs-studio blender ] [] ++
  mfunc.useDefault my.config.audio [] [];

}
