{ pkgs, lib, osConfig, ... }:

lib.mkIf osConfig.mine.graphics.enable

{

  home.packages = with pkgs; [

    ##################
    # Gnome Defaults #
    ##################

    # File
    gnome.nautilus
    gnome.file-roller

    # Terminal
    gnome.gnome-terminal
    gnome-console

    # Text
    gnome-text-editor
    gnome.gnome-characters

    # Pictures
    loupe

    # Font
    gnome.gnome-font-viewer

    # Movies
    gnome.totem

    # Phone
    calls

    # Recording
    gnome.gnome-sound-recorder

    # Scan
    gnome.simple-scan

    # Disk
    gnome.baobab
    gnome.gnome-disk-utility

    # Camera
    snapshot

    # Organising
    evince
    gnome.gnome-clocks
    gnome.gnome-calendar
    gnome.gnome-contacts
    gnome.gnome-calculator
    epiphany
    errands

    # Monitor
    gnome.gnome-system-monitor

    # Web
    gnome-connections

    # Admin
    gnome.gnome-weather

    # Passwords
    gnome.seahorse

    # Tools
    gnome.gnome-tweaks

    # Themes
    gnome-themes-extra

    ###############
    # Gnome Extra #
    ###############

    # System Monitor
    resources

    # Files
    warp
    raider
    curtail
    collision

    # Email
    evolution

    # Organising
    citations
    dialect
    # gaphor  # TODO Failing
    plots
    iotas
    denaro
    gnome-graphs
    lorem

    # Disk
    impression

    # Audio
    blanket

    # Music
    fretboard
    pkgs.unstable.decibels  # TODO 24.11

    # Look & Feel
    gradience

    # Image Editing
    drawing
    emblem
    eyedropper
    gnome-obfuscate

    # Video Editing
    video-trimmer

    # Download
    fragments
    parabolic

    # Media
    shortwave
    komikku
    newsflash
    wike

    # Cast
    gnome-network-displays

    # Chat
    fractal
    gnome.polari

    # CW
    telegraph

    # Encoding
    eartag
    identity
    textpieces
    paper-clip
    gnome-decoder
    metadata-cleaner

    # Hardware
    gnome-firmware

    # Virtualisation
    bottles
    gnome.gnome-boxes

    # Development
    gnome.dconf-editor
    gnome-builder
    d-spy
    sysprof

    ####################
    # Gnome Extensions #
    ####################

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
    gnomeExtensions.wintile-windows-10-window-tiling-for-gnome
    gnomeExtensions.panel-date-format
    gnomeExtensions.weather-oclock
    gnomeExtensions.customize-clock-on-lock-screen
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.appindicator

    ################
    # Applications #
    ################

    # XDG
    awf
    dconf

    # Networking
    wireshark
    hoppscotch

    # Files
    nextcloud-client

    # File organizing
    qdirstat

    # Disk
    gparted

    # Terminal
    alacritty
    cool-retro-term

    # Clipboard
    wl-clipboard

    # Keyboard
    wtype
    wshowkeys

    # Display
    wdisplays
    wlr-randr

    # VNC
    wayvnc

    # Virtualisation
    virt-manager

    # Image editing
    gimp
    inkscape

    # 3D
    cura

    # QR Code
    zbar

    # Music
    feishin

    # Video player
    vlc
    mpv
    celluloid

    # Casting
    catt

    # Streaming
    streamlink
    nodePackages.peerflix

    # Remote Desktop
    remmina
    moonlight-qt

    # Web
    electron

    # Chat
    discord
    signal-desktop
    element-desktop

    # Voice
    mumble

    # Office
    # Spellcheck
    hunspell
    hunspellDicts.en-us
    hunspellDicts.en-gb-ise
    hunspellDicts.pt-br
    hunspellDicts.it-it
    hunspellDicts.es-es

    # Grammar
    languagetool

    # Learning
    anki

    # Graph plotting
    gnuplot

    # Aviation
    # pkgs.custom.littlenavmap  # Not needed

    # Finance
    gnucash
    monero-gui

    # Info
    gource

    # Binary Visualiser
    binocle

    # RISC-V
    rars

    # Analiser
    smuview
    pulseview
    openhantek6022

    # Joysticks
    jstest-gtk
    python3Packages.ds4drv

    # Testing
    sdl-jstest

    # Radio
    chirp

    # Inputs
    opentrack

    # Emulation
    dosbox

  ] ++

  # Non minimal system packages
  (if (!osConfig.mine.minimal) then [

    # Video Editing
    kdenlive

    # Image Editing
    krita

    # Radio
    gqrx

  ] else []) ++

  # 64 bit only applications
  (if pkgs.stdenv.hostPlatform.isx86_64 then [

    # Password manager
    bitwarden

  ] else []) ++

  # Packages that do not work on arm
  (if (!pkgs.stdenv.hostPlatform.isAarch) then [

    # IDE
    arduino

    # Wine
    wine-wayland
    winetricks
    protontricks

    # Video Apps
    obs-studio

    # Reverse engineering
    ghidra-bin

  ] else []) ++

  # Software production software
  (if osConfig.mine.production.software then [

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

    # Virtual
    # vmware-horizon-client
    # vmware-workstation

  ] else []) ++

  # Business software
  (if osConfig.mine.production.business then [

    # Video
    zoom-us

  ] else []) ++

  # Electronics production software
  (if osConfig.mine.production.electronics then [

    # Electronics
    kicad

  ] else []) ++

  # Electronics and non arm
  (if ((!pkgs.stdenv.hostPlatform.isAarch) && osConfig.mine.production.electronics) then [

    # Electronics
    logisim

  ] else []) ++

  # 3D modelling software
  (if ((!pkgs.stdenv.hostPlatform.isAarch) && osConfig.mine.production.models) then [

    # Modeling & CAD
    blender
    freecad
    librecad

  ] else []) ++

  # Audio packages
  (if osConfig.mine.audio then [

    # Player
    amberol

    # Phone
    twinkle

    # Pipewire
    easyeffects

    # Audio Control
    paprefs
    pipecontrol
    pavucontrol

    # Patchers
    carla
    helvum
    qpwgraph
    raysession

  ] else []) ++

  # Audio for amd64
  (if (pkgs.stdenv.hostPlatform.isx86_64 && osConfig.mine.audio) then [

    # Audio Players
    spotify
    spot

  ] else []) ++

  # Video production
  (if (osConfig.mine.audio && osConfig.mine.production.video) then [

    # Video Editors
    davinci-resolve

  ] else []) ++

  # Audio production
  (if (osConfig.mine.audio && osConfig.mine.production.audio) then [

    # DAW
    reaper

    # Sequencer
    tuxguitar

    # Editor
    tenacity

    # Live
    guitarix

    # Plugins
    calf
    lsp-plugins
    zyn-fusion
    zita-at1

    # Samplers
    qsampler
    linuxsampler

  ] else []);

}
