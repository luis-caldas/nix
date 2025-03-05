{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [

    ###########
    # General #
    ###########

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

    # Bootable
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

    # Flashing
    avrdude
    heimdall
    dfu-programmer

    # ESP
    esphome

    # Running Programs
    steam-run

    # Tor
    tor

    # NFC
    mfoc
    mfcuk
    libnfc
    (proxmark3.override { withGeneric = true; })

    # Devices
    ltunify  # Logitech
    rtl-sdr  # RTL-SDR

    # Input
    xboxdrv
    linuxConsoleTools

    # Bluetooth
    bluetooth_battery

    # Documents
    pdfgrep

    # Web
    w3m

    # Download
    aria
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

    # Email
    meli
    neomutt

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
    neofetch
    screenfetch

    #########################
    # Development & Hacking #
    #########################

    # Shell
    shellcheck
    shellharden

    # Windows
    powershell

    # Srcipting
    ghostscript

    # C
    gcc
    cmake
    gnumake

    # LLVM
    llvm

    # Debug
    gdb
    gef
    valgrind

    # Fuzz
    ffuf

    # JSON
    jq

    # XML & YAML
    libxml2
    python3Packages.yq

    # Python
    python3Full

    # Ruby
    ruby

    # Javascript
    nodejs
    yarn

    # Java
    (jdk.override { enableJavaFX = true; })

    # Nix
    nixpkgs-review

    # Containers
    arion
    docker-compose
    hadolint

    # Markdown
    pandoc
    python3Packages.grip

    # Databases Clients
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
    gobuster

    # Logger
    logkeys

    # Reverse
    pev
    radare2

    # Memory
    volatility3

    # Flashing
    avrdude
    micronucleus
    dfu-util
    dfu-programmer

    # CAN
    can-utils
    python3Packages.can
    python3Packages.cantools
    python3Packages.scapy

    # UBI
    ubi_reader
    ubidump

    # AI
    ollama

    # MitM
    mitmproxy

    # Servers
    fileshare
    nodePackages.http-server
    (writeScriptBin "pyftp" "${python3.withPackages (ps: [ps.pyftpdlib])}/bin/python -m pyftpdlib \"$@\"")

    #########################

  ] ++

  # Packages for a non minimal systems
  (if (!osConfig.mine.minimal) then [

    # Pentest
    metasploit
    steghide
    stegseek
    pwncat

    # Binary
    python3Packages.binwalk-full

    # Haskell
    ghc

    # Web
    browsh
    firefox
    yt-dlp

    # KVM & Virtualisation
    qemu_full

    # Video
    ffmpeg-full

    ##### Compiled

    # Input
    pkgs.custom.x56linux

    # Download
    # pkgs.custom.n-m3u8dl-re  # TODO Failing

    #####

    ##### Development

    # Rust
    cargo
    rustc
    rustfmt

    #####


  ] else []) ++

  # Packages for non arm systems
  (if (!pkgs.stdenv.hostPlatform.isAarch) then [

    # Flashing
    flashrom

  ] else []) ++

  # Minimal and non arm
  (if ((!pkgs.stdenv.hostPlatform.isAarch) && (!osConfig.mine.minimal)) then [

    # Android Programs
    apktool

  ] else []) ++

  # LaTeX support
  (if osConfig.mine.tex then [

    # Tex with medium scheme
    texlive.combined.scheme-medium

  ] else []) ++

  # Audio support
  (if osConfig.mine.audio then [

    # Local player
    cmus

    # Tools
    pipewire
    alsa-utils
    pulseaudio

    # Mixers
    pamixer

    # Visualizer
    cli-visualizer

    # TUI mixer
    pamix
    ncpamixer

    # MPRIS controller
    playerctl

    # Morse code training
    aldo

  ] else []);

}
