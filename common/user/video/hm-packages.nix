{ my, mfunc, config, pkgs, mpkgs, ... }:
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    openbox
    conky
    rofi

    # Notifications
    dunst
    libnotify

    # Password manager
    bitwarden
    keepass

    # Clipboard
    clipster

    # XDG
    awf
    dconf
    gnome-themes-extra

    # Font
    gnome3.gnome-font-viewer

    # Monitors
    arandr

    # File manager
    gnome3.nautilus

    # Desktop lock
    xss-lock

    # Unclutter
    unclutter-xfixes

    # Joysticks
    jstest-gtk
    python3Packages.ds4drv

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

    # Remote Desktop
    remmina
    tigervnc

    # Calculator
    gnome3.gnome-calculator

    # Image editing
    gimp
    gpick
    krita
    inkscape

    # Video editing
    kdenlive

    # Scan
    gnome3.simple-scan

    # Camera
    webcamoid

    # Document viewer
    evince

    # Money
    gnucash

    # Image viewer
    sxiv

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

    # QR Code
    zbar

    # Video player
    mpv
    vlc

    # Casting
    catt

    # Screeshot
    scrot

    # Overlay
    xmagnify
    screenkey
    find-cursor
    mpkgs.boomer

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
  # Packages that do not work on arm
  mfunc.useDefault my.config.x86_64 [

    # IDE
    arduino

    # Email
    thunderbird

    # Wine
    winetricks
    protontricks
    wineWowPackages.staging

    # Video Apps
    obs-studio
    looking-glass-client

    # Reverse engineering
    ghidra-bin

  ] [] ++
  mfunc.useDefault my.config.graphical.touch [
  ] [] ++
  mfunc.useDefault my.config.graphical.production.electronics [

    # Electronics
    kicad

  ] [] ++
  mfunc.useDefault (my.config.x86_64 && my.config.graphical.production.electronics) [

    # Electronics
    logisim

  ] [] ++
  mfunc.useDefault (my.config.x86_64 && my.config.graphical.production.models) [

    # Modeling and cadding
    blender
    freecad
    librecad

  ] [] ++
  mfunc.useDefault my.config.audio [

    # Online radio
    icecast

    # Phone
    twinkle

    # Audio Control
    paprefs
    pavucontrol

  ] [] ++
  mfunc.useDefault (my.config.audio && my.config.graphical.production.video) [

    # mpkgs.davinci-resolve

  ] [] ++
  mfunc.useDefault (my.config.audio && my.config.graphical.production.audio) [

    # Music production
    jack2
    cadence
    reaper
    tuxguitar
    tenacity
    calf
    guitarix
    linuxsampler
    qsampler
    zyn-fusion
    zita-at1

  ] [];
}
