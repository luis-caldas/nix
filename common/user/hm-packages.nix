{ my, mfunc, pkgs, mpkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Basic
    tmux
    htop
    gotop
    less
    screen
    parallel
    nix-tree

    # Bin manipulation
    john
    hashcat
    radare2
    hexedit
    binutils
    steghide
    python3Packages.binwalk-full

    # Web tools
    w3m
    wget
    nmap
    aria
    bind
    nload
    inetutils
    # mpkgs.python3Packages.anime-downloader

    # Keyboard
    xorg.xmodmap
    xdotool
    numlockx

    # Window manager manipulation
    wmctrl

    # Serial
    picocom
    minicom

    # Boot tools
    efibootmgr

    # System monitoring
    usbutils
    pciutils

    # File manipulation
    tree
    file
    p7zip
    unrar
    samba
    archivemount

    # Net tools
    ethtool

    # Audio & Video manipulation
    ffmpeg-full
    imagemagick
    waifu2x-converter-cpp

    # Android
    gitRepo
    simg2img

    # KVM & Virt
    qemu
    OVMF

    # Drives
    hdparm
    nvme-cli

    # Encryption
    gnupg
    openssl
    cryptsetup

    # Passwork hash generator
    mkpasswd

    # User tools
    irssi
    neomutt

    # Clipboard
    xclip

    # Image
    jp2a
    libqrencode

    # Radio
    rtl-sdr

    # NFC
    pcsctools
    pcsclite

    # Fetching packages
    neofetch
    screenfetch

    # LLVM
    llvm

    # System
    stress
    evtest

    # Sensors
    lm_sensors

    #######
    # Dev #
    #######

    # Shell
    bc
    shellcheck
    inotify-tools

    # C
    gcc
    cmake
    gnumake

    # Haskell
    ghc

    # JSON
    jq

    # Python
    python2Full
    python3Full
    python3Packages.pip

    # Ruby
    ruby

    # Javascript
    nodejs
    yarn
    nodePackages.http-server

    # Java
    adoptopenjdk-jre-bin

    # Markdown
    python3Packages.grip

    #######

  ] ++
  mfunc.useDefault my.config.x86_64 [ flashrom ] [] ++
  mfunc.useDefault my.config.tex [ texlive.combined.scheme-medium ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [
    cmus
    alsaUtils
    cli-visualizer
    ncpamixer
    playerctl
    ncspot
  ] [];

}
