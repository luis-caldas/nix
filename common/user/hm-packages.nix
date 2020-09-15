{ my, mfunc, upkgs, pkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Basic
    tmux
    htop
    gotop
    less
    screen
    parallel

    # Bin manipulation
    john
    hashcat
    radare2
    hexedit
    binutils
    steghide
    python38Packages.binwalk-full

    # Web tools
    w3m
    wget
    nmap
    aria
    bind
    nload
    inetutils

    # Keyboard
    xorg.xmodmap
    xdotool
    numlockx

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
    python27Full
    python27Packages.pip
    python38Full
    python38Packages.pip

    # Ruby
    ruby

    # Javascript
    nodejs
    yarn

    # Java
    adoptopenjdk-jre-bin

    # Markdown
    python38Packages.grip

    #######

  ] ++
  mfunc.useDefault my.config.x86_64 [ flashrom ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [
    cmus
    alsaUtils
    cli-visualizer
    ncpamixer
    playerctl
    # Unstable (for mpris support)
    upkgs.ncspot
  ] [];

}
