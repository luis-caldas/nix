{ my, mfunc, upkgs, pkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Basic
    tmux
    htop
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

    # Fetching packages
    neofetch
    screenfetch

    # LLVM
    llvm

    # System
    stress
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
