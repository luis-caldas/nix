{ pkgs, lib, osConfig, ... }:
let

  gnomeDefaultPackages = with pkgs; [
    # File
    nautilus
    file-roller
    # Terminal
    gnome-console
    # Text
    gnome-text-editor
    gnome-characters
    # Pictures
    loupe
    # Font
    gnome-font-viewer
    # Movies
    showtime
    # Phone
    calls
    # Recording
    gnome-sound-recorder
    # Scan
    simple-scan
    # Disk
    baobab
    gnome-disk-utility
    # Camera
    snapshot
    # Organising
    papers
    gnome-clocks
    gnome-calendar
    gnome-contacts
    gnome-calculator
    epiphany
    errands
    # Monitor
    gnome-system-monitor
    # Web
    gnome-connections
    # Admin
    gnome-weather
    # Passwords
    seahorse
    # Tools
    gnome-tweaks
    # Themes
    gnome-themes-extra
  ];

  gnomeExtraPackages = with pkgs; [
    # System monitoring
    resources
    # Files
    warp
    raider
    curtail
    collision
    # Email
    geary
    evolution
    # Organising
    citations
    dialect
    gaphor
    iotas
    denaro
    gnome-graphs
    lorem
    apostrophe
    # Disk
    impression
    # Audio
    blanket
    audio-sharing
    # Music
    mousai
    decibels
    fretboard
    drum-machine
    # Screenshot
    gradia
    # Image Editing
    drawing
    emblem
    switcheroo
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
    polari
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
    gnome-boxes
    # Development
    binary
    dconf-editor
    gnome-builder
    d-spy
    sysprof
  ];

  gnomeExtensionPackages = with pkgs; [
    gnome-menus
    gnomeExtensions.arcmenu
    gnomeExtensions.vitals
    gnomeExtensions.blur-my-shell
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.mpris-label
    gnomeExtensions.just-perfection
    gnomeExtensions.dash-to-dock
    gnomeExtensions.media-controls
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.panel-date-format
    gnomeExtensions.weather-oclock
    gnomeExtensions.customize-clock-on-lock-screen
    gnomeExtensions.appindicator
    gnomeExtensions.smart-home
    #
    custom.gnome-legacy-gtk
  ];

  applicationPackages = with pkgs; [
    # XDG
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
    jellyfin-desktop
    # Remote Desktop
    remmina
    moonlight-qt
    # Maintenance
    winbox4
    # Web
    electron
    # Chat
    discord
    signal-desktop
    element-desktop
    # Voice
    mumble
    # Documents
    diffpdf
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
    # RISC V
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
  ];

  # Office
  # Spellcheck
  dictionaryPackages = with pkgs;
    let
      hunDicts = motherDict: with motherDict; [
        en-gb-ise
        en-us
        pt-br
        it-it
        es-es
      ];
      aspDicts = motherDict: with motherDict; [
        en
        en-computers
        en-science
        pt_BR
        it
        es
      ];
    in
      [
        hyphen
        hyphenDicts.en-us
        (hunspell.withDicts hunDicts)
        (aspellWithDicts aspDicts)
      ]
      ++ (hunDicts pkgs.hunspellDicts)
      ++ (aspDicts pkgs.aspellDicts);

  fullDesktopPackages = with pkgs; [
    # Video Editing
    kdePackages.kdenlive
    # Image Editing
    krita
    # Radio
    gqrx
  ];

  passwordManagerPackages = with pkgs; [
    # Password manager
    bitwarden-desktop
  ];

  compatibilityApplications = with pkgs; [
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
  ];

  softwareProductionPackages = with pkgs; [
    # Jetbrains paid
    jetbrains.pycharm
    jetbrains.idea
    jetbrains.datagrip
    jetbrains.webstorm
    jetbrains.clion
    jetbrains.rust-rover
    # Jetbrains free
    jetbrains.pycharm-oss
    jetbrains.idea-oss
    # Packet tracers
    gns3-gui
    gns3-server
    # Visual
    drawio
    pandoc-drawio-filter
    # Maths
    octaveFull
    # Virtual
    # VMware horizon client
    # VMware workstation
  ];

  businessPackages = with pkgs; [
    # Video
    zoom-us
    teams-for-linux
  ];

  electronicsPackages = with pkgs; [
    # Electronics
    kicad
  ];

  electronicsSimulationPackages = with pkgs; [
    # Electronics
    logisim
  ];

  modelPackages = with pkgs; [
    # Modeling & CAD
    blender
    freecad
    librecad
    # House
    sweethome3d.application
    # Slicer
    orca-slicer
  ];

  audioPackages = with pkgs; [
    # Phone
    twinkle
    # PipeWire
    easyeffects
    # Audio Control
    paprefs
    pipecontrol
    pwvucontrol
    # Patchers
    carla
    helvum  # TODO 26.05 crosspipe
  ];

  streamingMusicPackages = with pkgs; [
    # Audio Players
    spotify
  ];

  videoProductionPackages = with pkgs; [
    # Video Editors
    davinci-resolve
  ];

  audioProductionPackages = with pkgs; [
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
    zita-at1
    lsp-plugins
    zynaddsubfx
    # Bridge
    yabridge
    yabridgectl
    # Samplers
    qsampler
    linuxsampler
  ];

in
  lib.mkIf osConfig.mine.graphics.enable {
    home.packages = lib.lists.flatten [
      gnomeDefaultPackages
      gnomeExtraPackages
      gnomeExtensionPackages
      applicationPackages
      dictionaryPackages
      # Non minimal system packages
      (lib.optionals (!osConfig.mine.minimal) fullDesktopPackages)
      # 64 bit only applications
      (lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) passwordManagerPackages)
      # Packages that do not work on arm
      (lib.optionals (!pkgs.stdenv.hostPlatform.isAarch) compatibilityApplications)
      # Software production software
      (lib.optionals osConfig.mine.production.software softwareProductionPackages)
      # Business software
      (lib.optionals osConfig.mine.production.business businessPackages)
      # Electronics production software
      (lib.optionals osConfig.mine.production.electronics electronicsPackages)
      # Electronics and non arm
      (lib.optionals (osConfig.mine.production.electronics && (!pkgs.stdenv.hostPlatform.isAarch)) electronicsSimulationPackages)
      # 3D modelling software
      (lib.optionals (osConfig.mine.production.models && (!pkgs.stdenv.hostPlatform.isAarch)) modelPackages)
      # Audio packages
      (lib.optionals osConfig.mine.audio audioPackages)
      # Audio for amd64
      (lib.optionals (osConfig.mine.audio && (pkgs.stdenv.hostPlatform.isx86_64)) streamingMusicPackages)
      # Video production
      (lib.optionals (osConfig.mine.audio && osConfig.mine.production.video) videoProductionPackages)
      # Audio production
      (lib.optionals (osConfig.mine.audio && osConfig.mine.production.audio) audioProductionPackages)
    ];
  }
