{ my, mfunc, pkgs, mpkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Bin manipulation
    john
    flips
    hashcat
    radare2
    hexedit
    binutils
    geteltorito
    unixtools.xxd
    mpkgs.steghide
    python3Packages.binwalk-full

    # Disk
    pv
    ncdu
    parted
    testdisk
    smartmontools

    # Flashing tools
    avrdude
    heimdall
    dfu-programmer

    # Web tools
    w3m
    wget
    nmap
    aria
    bind
    atftp
    nload
    socat
    browsh
    firefox
    inetutils
    youtube-dl

    # Debugger
    gdb

    # Pen
    tor
    ncrack
    sqlmap
    thc-hydra

    # Sniffer
    wireshark

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
    grub2
    (pkgs.writeShellScriptBin "grub-install-efi" "exec -a $0 ${grub2_efi}/bin/grub-install $@")
    efibootmgr

    # System monitoring
    usbutils
    pciutils

    # File manipulation
    tree
    file
    pigz
    p7zip
    unrar
    samba
    jdupes
    rmtrash

    # File systems
    jmtpfs
    archivemount

    # Optical disks
    cdrkit
    dvdplusrwtools

    # Net tools
    ethtool
    shadowsocks-libev

    # Audio & Video manipulation
    potrace
    imagemagick
    libqrencode
    ffmpeg-full
    ghostscript
    waifu2x-converter-cpp
    python3Packages.pywal

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
    khal
    irssi
    _3llo
    neomutt

    # Clipboard
    xclip

    # Image
    jp2a

    # Banner
    figlet

    # Logitech
    ltunify

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
    shellcheck
    xdg-user-dirs
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

    # Ruby
    ruby

    # Javascript
    nodejs
    yarn
    nodePackages.http-server
    nodePackages.node2nix

    # Java
    adoptopenjdk-jre-openj9-bin-16

    # Markdown
    python3Packages.grip

    #######

  ] ++
  mfunc.useDefault my.config.x86_64 [

    # Bin
    apktool

    # Flash utilities
    flashrom

  ] [] ++
  mfunc.useDefault my.config.services.fingerprint [
    fwupd
  ] [] ++
  mfunc.useDefault my.config.tex [ texlive.combined.scheme-medium ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [

    # Local player
    cmus

    # Alsa tools
    alsaUtils

    # Visualizer
    cli-visualizer

    # TUI mixer
    pamix
    ncpamixer

    # MPRIS controller
    playerctl

    # Morse code training
    aldo

  ] [];

}
