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
    gnome.gnome-calculator
    epiphany

    # Monitor
    gnome.gnome-system-monitor

    # Web
    gnome-connections

    # Passwords
    gnome.seahorse

    # Tools
    gnome.gnome-tweaks

    # Themes
    gnome-themes-extra

    ###############
    # Gnome Extra #
    ###############

    # Files
    warp
    raider
    curtail
    collision

    # Organising
    evolution
    # citations  # TODO Failing
    dialect
    gaphor
    plots
    iotas
    denaro

    # Disk
    impression

    # Audio
    blanket

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

    # Media
    shortwave
    komikku
    newsflash
    wike

    # Chat
    gnome.polari

    # Web
    tangram

    # Encoding
    eartag
    identity
    # textpieces  # TODO Broken
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

    ################
    # Applications #
    ################

    # XDG
    awf
    dconf

    # Files
    nextcloud-client

    # File organizing
    qdirstat

    # Terminal
    kitty
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

    # Image editing
    gimp
    inkscape

    # QR Code
    zbar

    # Comics
    mcomix

    # Video player
    vlc
    mpv
    memento
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

    # Email
    thunderbird

    # Chat
    discord
    signal-desktop
    # schildichat-desktop  # Insecure
    # whatsapp-for-linux  # Browser version is better

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

    # Learning
    anki

    # Graph plotting
    gnuplot

    # Money
    gnucash

    # Info
    gource

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
    looking-glass-client

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
