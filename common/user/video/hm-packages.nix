{ my, mfunc, upkgs, config, pkgs, ... }:
{

  nixpkgs.config.allowUnsupportedSystem = true;

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    openbox
    conky
    rofi

    # GTK
    upkgs.gtk3

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

    # Document viewer
    evince

    # Office
    libreoffice

    # Image viewer
    sxiv

    # Email
    thunderbird

    # Wallpaper
    nitrogen

    # Voip
    mumble

    # Testing
    gource
    glxinfo

    # Virtualization
    spice-gtk

    # Video player
    mpv
    vlc

    # Casting
    catt

    # Screeshot
    scrot

    # Streaming
    streamlink

    # Radio
    gqrx

  ] ++
  # Unsable packages
  [

    # Window Composer
    upkgs.picom

  ] ++
  mfunc.useDefault my.config.x86_64 [

    # Video Apps
    obs-studio
    upkgs.blender
    upkgs.looking-glass-client

  ] [] ++
  mfunc.useDefault my.config.audio [

    # Audio Control
    pavucontrol

  ] [] ++
  mfunc.useDefault my.config.graphical.production [

    # Music production
    jack2
    upkgs.cadence
    reaper
    calf
    guitarix
    linuxsampler
    qsampler

  ] [];
}
