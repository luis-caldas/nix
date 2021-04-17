{ my, mfunc, config, pkgs, ... }:
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
    sdl-jstest

    # Virtualization
    spice-gtk

    # Emulation
    dosbox

    # Wine
    winetricks
    protontricks
    wineWowPackages.staging

    # Video player
    mpv
    vlc

    # Casting
    catt

    # Screeshot
    scrot

    # Streaming
    streamlink
    nodePackages.peerflix

    # Radio
    gqrx
    chirp

  ] ++
  # Unsable packages
  [

    # Window Composer
    picom

  ] ++
  mfunc.useDefault my.config.x86_64 [

    # Video Apps
    obs-studio
    looking-glass-client

    # Reverse engineering
    ghidra-bin

  ] [] ++
  mfunc.useDefault (my.config.x86_64 && my.config.graphical.prod3d) [

    # Latest blender if 3d production is set
    blender

  ] [] ++
  mfunc.useDefault my.config.audio [

    # Online radio
    icecast

    # Audio Control
    paprefs
    pavucontrol

  ] [] ++
  mfunc.useDefault my.config.graphical.production [

    # Music production
    jack2
    cadence
    reaper
    audacity
    calf
    guitarix
    linuxsampler
    qsampler

  ] [];
}
