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

    # Paritioning
    parted

    # Rescue
    ddrescue

    # Bootable
    ventoy-full

    # Bitlocker
    dislocker

    # Optical Disk Tools
    bchunk
    ccd2iso

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

    # Virtualisation
    virt-manager

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
    pcsctools
    pcsclite

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
    nodePackages.http-server

    # Java
    adoptopenjdk-jre-openj9-bin-16

    # Rust
    cargo
    rustc
    rustfmt

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

    # Networking
    subnetcalc

    # Password
    john
    hashcat

    # Brute
    ncrack
    sqlmap
    thc-hydra

    # Networking
    inetutils

    # Sniffer
    wireshark

    # Logger
    logkeys

    # Reverse
    radare2

    # Flashing
    avrdude
    micronucleus
    dfu-util
    dfu-programmer

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
