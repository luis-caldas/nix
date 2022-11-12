{ my, mfunc, config, pkgs, mpkgs, ... }:
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    openbox
    conky
    rofi

    # Xorg
    xorg.xwininfo

    # Video
    xorg.xdpyinfo

    # Notifications
    dunst
    libnotify

    # Password manager
    keepass

    # Policies
    lxqt.lxqt-policykit

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

    # VNC
    x11vnc

    # File manager
    gnome3.nautilus

    # Image viewer
    gnome3.eog

    # File organizing
    qdirstat

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

    # Term
    cool-retro-term

    # Web
    electron

    # Email
    thunderbird

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
    inkscape

    # Scan
    gnome3.simple-scan

    # Document viewer
    evince

    # Money
    gnucash

    # Comics
    mcomix3

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

    # Inputs
    opentrack

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
    chirp

  ] ++
  # Unsable packages
  [

    # Window Composer
    picom

  ] ++
  mfunc.useDefault (!my.config.system.minimal) [

    # Video editing
    kdenlive

    # Image editing
    krita

    # Camera
    webcamoid

    # Radio
    gqrx

  ] [] ++
  mfunc.useDefault (my.arch == my.reference.x64) [

    # Password manager
    bitwarden

  ] [] ++
  # Packages that do not work on arm
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # IDE
    arduino

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
  mfunc.useDefault my.config.graphical.production.software [

    # Editors
    jetbrains.pycharm-community
    jetbrains.pycharm-professional
    jetbrains.webstorm
    jetbrains.clion

  ] [] ++
  mfunc.useDefault my.config.graphical.production.business [

    # Video
    zoom-us

  ] [] ++
  mfunc.useDefault my.config.graphical.production.electronics [

    # Electronics
    kicad

  ] [] ++
  mfunc.useDefault (((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) && my.config.graphical.production.electronics) [

    # Electronics
    logisim

  ] [] ++
  mfunc.useDefault (((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) && my.config.graphical.production.models) [

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
  mfunc.useDefault ((my.arch == my.reference.x64) && my.config.audio) [

    # Audio player
    (writeShellScriptBin "spotify" ''
      "${spotify}/bin/spotify" --force-device-scale-factor="''${GDK_SCALE}" "''${@}"
    '')

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
    lsp-plugins

  ] [];
}
