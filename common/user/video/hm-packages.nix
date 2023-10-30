{ my, mfunc, config, pkgs, mpkgs, ... }:
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    conky
    xorg.xprop  # Needed for xwayland scaling

    # Gnome
    gnome.gnome-terminal
    gnome-console
    gnome.baobab
    gnome.cheese
    gnome.eog
    gnome-text-editor
    gnome.gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-characters
    gnome.gnome-system-monitor
    gnome-connections
    gnome.file-roller
    gnome.seahorse
    gnome.gnome-tweaks
    gnome.gnome-disk-utility
    gnome.totem
    epiphany
    # gnome.camera ? # TODO 23.11

    # Gnome Extras
    evolution
    # cartridges  # TODO 23.11
    blanket
    bottles
    citations
    # collision   # TODO 23.11
    curtail
    gnome-decoder
    dialect
    drawing
    eartag
    emblem
    eyedropper
    raider
    fragments
    gaphor
    identity
    iotas
    # impression  # TODO 23.11
    komikku
    metadata-cleaner
    newsflash
    gnome-obfuscate
    # plots  # TODO 23.11
    gnome.polari
    shortwave
    tangram
    # text-pieces  # TODO 23.11
    video-trimmer
    warp
    wike

    # Gnome Dev
    gnome-builder
    gnome.gnome-boxes
    d-spy
    gnome.dconf-editor
    sysprof

    # Gnome Extensions
    gnome-menus
    gnomeExtensions.arcmenu
    gnomeExtensions.vitals
    gnomeExtensions.blur-my-shell
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.mpris-label
    gnomeExtensions.remove-app-menu
    gnomeExtensions.just-perfection
    gnomeExtensions.dash-to-dock
    gnomeExtensions.media-controls
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.tray-icons-reloaded

    # Files
    nextcloud-client

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

    # Office
    # libreoffice

    # Spellchecking (for libreoffice)
    hunspell
    hunspellDicts.en-us
    hunspellDicts.en-gb-ise
    # hunspellDicts.pt-br  # TODO 23.11
    hunspellDicts.it-it
    hunspellDicts.es-es

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
    discord
    signal-desktop
    # schildichat-desktop  # TODO 23.11 electron marked as insecure
    # whatsapp-for-linux  # Browser version is better

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
    memento
    celluloid

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
    # bitwarden  # TODO 23.11 electron marked as insecure

  ] [] ++
  # Packages that do not work on arm
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # IDE
    arduino

    # Wine
    wine-wayland
    winetricks
    protontricks

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

    # Player
    amberol

    # Phone
    twinkle

    # Pipewire
    easyeffects

    # Audio Control
    paprefs
    pavucontrol

    # Patchers
    carla
    helvum
    qpwgraph
    raysession

  ] [] ++
  mfunc.useDefault ((my.arch == my.reference.x64) && my.config.audio) [

    # Audio player
    spotify
    spot

  ] [] ++
  mfunc.useDefault (my.config.audio && my.config.graphical.production.video) [

    davinci-resolve

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
