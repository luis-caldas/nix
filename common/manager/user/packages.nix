{ pkgs, lib, osConfig, ... }:
let

  basePackages = with pkgs; [
    # Binary
    flips
    xdelta
    geteltorito
    payload-dumper-go
    # Text
    recode
    # Usage
    duf
    ncdu
    # Mounting
    sshfs
    jmtpfs
    archivemount
    # Disk
    squashfsTools
    simg2img
    dmg2img
    # Disk Data
    pkgs.custom.bs
    # Disk Clearing
    zerofree
    # Disk Test
    f3
    testdisk
    # Rescue
    ddrescue
    # Boot
    ventoy-full
    # Bitlocker
    dislocker
    # Optical Disk Tools
    bchunk
    ccd2iso
    pkgs.custom.ccd2cue
    # Optical Writing
    cdrkit
    dvdplusrwtools
    # Duplicates
    jdupes
    rdfind
    rmlint
    rmtrash
    czkawka
    # Time
    libfaketime
    # Versioning
    subversion
    # Running programs
    steam-run
    # Tor
    tor
    # Documents
    pdfgrep
    poppler-utils
    # Speed Test
    fast-cli-zig
    # Web
    w3m
    # Download
    aria2
    bento4
    # Web Services
    frp
    ntp
    atftp
    samba
    # DNS
    bind
    knot-dns
    # Web Monitor
    nload
    # Password
    bitwarden-cli
    # Messaging
    iamb
    irssi
    # AI
    chatgpt-cli
    # Media Manipulation
    imagemagick
    potrace
    qrencode
    waifu2x-converter-cpp
    pywal
    # EXIF
    exiftool
    # Android
    avbroot
    gitRepo
    # Android Video
    scrcpy
    # ASCII
    jp2a
    boxes
    cowsay
    figlet
    toilet
    pipes
    cbonsai
    tty-clock
    # Terminal Recording
    vhs
    doitlive
    asciinema
    asciinema-agg
    asciinema-scenario
    # Chemistry
    element
    # Fetchers
    pfetch
    fastfetch
    screenfetch
  ];

  hardwarePackages = with pkgs; [
    # Flashing
    avrdude
    heimdall
    dfu-programmer
    # ESP
    esphome
    # NFC
    mfoc
    mfcuk
    libnfc
    (proxmark3.override { withGeneric = true; })
    # Devices
    ltunify  # Logitech
    rtl-sdr  # RTL SDR
    rtl_433
    # HackRF One
    hackrf
    soapysdr-with-plugins
    # Radio
    readsb
    dump1090-fa
    # Input
    linuxConsoleTools
    # Bluetooth
    bluetooth_battery
  ];

  developmentPackages = with pkgs; [
    # Input
    rlwrap
    # Shell
    shellcheck
    shellharden
    # Windows
    powershell
    # Scripting
    ghostscript
    # C
    gcc
    cmake
    gnumake
    # LLVM
    llvm
    # Python
    python3
    # Ruby
    ruby
    # Javascript
    nodejs
    yarn
    # Java
    (jdk.override { enableJavaFX = true; })
    # Debug
    gdb
    gef
    valgrind
    # Fuzz
    ffuf
    # Analysis
    python3Packages.angr
    # XML & YAML
    libxml2
    yamllint
    python3Packages.yq
    # Reverse
    pev
    radare2
    # Memory
    volatility2-bin
    volatility3
    # Flashing
    micronucleus
    dfu-util
    # CAN
    can-utils
    python3Packages.scapy
    python3Packages.cantools
    python3Packages.python-can
    # UBI
    ubi_reader
    ubidump
    # Nix
    nixpkgs-review
    # Containers
    arion
    docker-compose
    hadolint
    # Markdown
    pandoc
    python3Packages.grip
    # Database clients
    mycli
    pgcli
    litecli
    usql
    mongosh
    sqlitebrowser
    # Networking
    subnetcalc
    # Certificates
    certbot
    acme-sh
    # Password
    john
    hashcat
    # Brute
    ncrack
    sqlmap
    thc-hydra
    # Fuzz
    aflplusplus
    # Networking
    mtr
    inetutils
    # Web
    (lib.lowPrio gobuster)
    # Logger
    logkeys
    # MitM
    mitmproxy
    # Servers
    fileshare
    copyparty
    http-server
    (writeScriptBin "pyftp" "${python3.withPackages (ps: [ps.pyftpdlib])}/bin/python -m pyftpdlib \"$@\"")
    # AI
    ollama
    whisper-ctranslate2
  ];

  workstationPackages = with pkgs; [
    # Pentest
    metasploit
    steghide
    stegseek
    pwncat
    # Binary
    binwalk
    # Web
    browsh
    firefox
    yt-dlp
    # Video
    ffmpeg-full
    # Download
    n-m3u8dl-re
    # KVM & Virtualisation
    qemu_full
    # Haskell
    ghc
    # Rust
    rustup
    # Input
    pkgs.custom.x56linux
  ];

  flashingTools = with pkgs; [
    # Flashing
    flashrom
  ];

  androidTools = with pkgs; [
    # Android programs
    apktool
    # ADB
    android-tools
  ];

  texPackages = with pkgs; [
    # TeX with medium scheme
    texlive.combined.scheme-medium
  ];

  audioPackages = with pkgs; [
    # Local player
    cmus
    # Tools
    pipewire
    alsa-utils
    pulseaudio
    # Mixers
    pamixer
    # TUI mixer
    pamix
    ncpamixer
    # MPRIS controller
    playerctl
    # Morse code training
    aldo
  ];

in {
  home.packages = lib.lists.flatten [
    basePackages
    developmentPackages
    # Packages for non minimal systems
    (lib.optionals (!osConfig.mine.minimal) hardwarePackages)
    (lib.optionals (!osConfig.mine.minimal) workstationPackages)
    # Packages for non ARM systems
    (lib.optionals (!pkgs.stdenv.hostPlatform.isAarch) flashingTools)
    # Minimal and non ARM
    (lib.optionals (!pkgs.stdenv.hostPlatform.isAarch && !osConfig.mine.minimal) androidTools)
    # LaTeX support
    (lib.optionals osConfig.mine.tex texPackages)
    # Audio support
    (lib.optionals osConfig.mine.audio audioPackages)
  ];
}
