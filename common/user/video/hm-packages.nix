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

    # Graph plotting
    gnuplot

    # Web
    electron

    # Torrenting
    deluge

    # Calculator
    gnome3.gnome-calculator

    # Image editing
    gimp
    inkscape

    # Scan
    gnome3.simple-scan

    # Document viewer
    evince

    # Office
    libreoffice

    # Printers
    system-config-printer

    # Money
    gnucash

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
    chirp

  ] ++
  # Unsable packages
  [

    # Window Composer
    upkgs.picom

  ] ++
  mfunc.useDefault my.config.x86_64 [

    # Video Apps
    obs-studio
    upkgs.looking-glass-client

  ] [] ++
  mfunc.useDefault (my.config.x86_64 && my.config.graphical.prod3d) [

    # Latest blender if 3d production is set
    upkgs.blender

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
