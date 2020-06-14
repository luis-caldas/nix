{ my, mfunc, upkgs, pkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Basic
    tmux
    htop
    less
    screen

    # Bin manipulation
    radare2
    hexedit
    binutils
    python38Packages.binwalk-full

    # Web tools
    w3m
    wget
    nmap
    nload
    bind

    # Keyboard
    xorg.xmodmap

    # Serial
    picocom
    minicom

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

    # Emulation
    qemu

    # HDD
    hdparm

    # Encryption
    gnupg
    openssl
    cryptsetup

    # Passwork hash generator
    mkpasswd

    # User tools
    mutt
    irssi

    # Image viewer
    jp2a

    # Fetching packages
    neofetch
    screenfetch

    # LLVM
    llvm

    # System
    evtest

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

    #######

  ] ++
  mfunc.useDefault my.config.x86_64 [ flashrom ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [ alsaUtils cli-visualizer ncpamixer playerctl upkgs.ncspot ] [];

}
