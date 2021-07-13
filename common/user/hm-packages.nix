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
    apktool
    binutils
    geteltorito
    unixtools.xxd
    mpkgs.steghide
    python3Packages.binwalk-full

    # Disk
    parted

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
    inetutils
    youtube-dl
    mpkgs.python3Packages.anime-downloader

    # Pen
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

    # File systems
    jmtpfs
    ntfs3g
    archivemount

    # Net tools
    ethtool
    shadowsocks-libev

    # Audio & Video manipulation
    ffmpeg-full
    imagemagick
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
    irssi
    neomutt

    # Clipboard
    xclip

    # Image
    jp2a
    libqrencode

    # Banner
    figlet

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
  mfunc.useDefault my.config.x86_64 [ flashrom ] [] ++
  mfunc.useDefault my.config.services.fingerprint [
    fwupd
    mpkgs.python3Packages.open-fprintd
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
    ncpamixer

    # MPRIS controller
    playerctl

    # Spotify
    ncspot

    # Morse code training
    aldo

  ] [];

}
