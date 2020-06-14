{ my, mfunc, upkgs, config, pkgs, ... }:
{

  nixpkgs.config.allowUnsupportedSystem = true;

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    openbox
    conky
    rofi

    # XDG
    dconf
    gnome-themes-extra

    # Monitors
    arandr

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

    # Streaming
    streamlink

  ] ++
  # Unsable packages
  [
    upkgs.picom
  ] ++
  mfunc.useDefault my.config.games [ multimc mednafen mednaffe mupen64plus ] [] ++
  mfunc.useDefault my.config.x86_64 [ obs-studio blender ] [] ++
  mfunc.useDefault my.config.audio [ pavucontrol ] [];

}
