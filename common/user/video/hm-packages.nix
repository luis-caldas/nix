{ my, mfunc, config, pkgs, mpkgs, ... }:
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    conky
    xorg.xprop  # Needed for xwayland scaling

    # Gnome
    gnome.gnome-terminal
    gnome.baobab
    gnome.cheese
    gnome.eog
    gnome-text-editor
    gnome.gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-characters
    gnome.gnome-system-monitor
    gnome-connections

    # Video
    wlsunset

    # Launcher
    rofi-wayland

    # Status Bar
    waybar

    # Terminal
    kitty

    # Notifications
    dunst
    libnotify

    # Screenshot
    grim
    slurp

    # Password manager
    keepass

    # Policies
    lxqt.lxqt-policykit

    # Clipboard
    wl-clipboard

    # Keyboard
    wtype

    # XDG
    awf
    dconf
    gnome-themes-extra

    # Font
    gnome.gnome-font-viewer

    # Monitors
    wdisplays
    wlr-randr

    # VNC
    wayvnc

    # File manager
    gnome3.nautilus

    # Image viewer
    gnome3.eog

    # File organizing
    qdirstat

    # Joysticks
    jstest-gtk
    python3Packages.ds4drv

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
    gnome.gnome-calculator

    # Image editing
    gimp
    inkscape

    # Picker
    hyprpicker

    # Scan
    gnome3.simple-scan

    # Document viewer
    evince

    # Money
    gnucash

    # Comics
    mcomix3

    # Wallpaper
    hyprpaper

    # Voip
    mumble

    # Chat
    signal-desktop

    # Info
    gource

    # Testing
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

    # Overlay
    wshowkeys

    # Streaming
    streamlink
    nodePackages.peerflix

    # Radio
    chirp

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
  mfunc.useDefault my.config.graphical.production.software [

    # Jetbrains paid
    jetbrains.pycharm-professional
    jetbrains.idea-ultimate
    jetbrains.datagrip
    jetbrains.webstorm
    jetbrains.clion

    # Jetbrains free
    jetbrains.pycharm-community
    jetbrains.idea-community

    # Packet tracers
    ciscoPacketTracer8
    gns3-gui
    gns3-server

    # Visual
    drawio
    pandoc-drawio-filter

    # Maths
    octaveFull

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

    # Phone
    twinkle

    # Audio Control
    paprefs
    pavucontrol

    # Patchers
    carla
    helvum

  ] [] ++
  mfunc.useDefault ((my.arch == my.reference.x64) && my.config.audio) [

    # Audio player
    spotify

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
