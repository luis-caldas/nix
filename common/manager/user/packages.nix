{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [

    ###########
    # General #
    ###########

    # Binary
    flips
    xdelta
    ubi_reader
    geteltorito
    payload-dumper-go

    # Usage
    duf
    ncdu

    # Mounting
    sshfs
    jmtpfs
    archivemount

    # Disk
    squashfsTools
    smartmontools

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

    # Time
    libfaketime

    # Versioning
    subversion

    # Flashing
    avrdude
    heimdall
    dfu-programmer

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
    pkgs.custom.x56linux
    linuxConsoleTools

    # Bluetooth
    bluetooth_battery

    # Web
    w3m

    # Download
    aria

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
    irssi
    gomuks

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
    simg2img

    # Android Video
    scrcpy

    # ASCII
    jp2a
    figlet
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
    gdb
    cmake
    gnumake

    # LLVM
    llvm

    # Debug
    valgrind

    # Fuzz
    ffuf

    # JSON
    jq

    # XML & YAML
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

    # Networking
    inetutils

    # Logger
    logkeys

    # Reverse
    radare2

    # Flashing
    avrdude
    micronucleus
    dfu-util
    dfu-programmer

    # Live
    can-utils

    # AI
    ollama

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

    # Binary
    python3Packages.binwalk-full

    # Haskell
    ghc

    # Web
    browsh
    firefox
    youtube-dl

    # KVM & Virtualisation
    qemu_full

    # Video
    ffmpeg-full

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
    alsaUtils
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
