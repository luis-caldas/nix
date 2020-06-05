{ pkgs, ... }:
let
  my = import ../../config.nix;
  mfunc = import ../../functions/func.nix;
in
{

  home.packages = with pkgs; [

    # Basic
    tmux
    htop
    less
    screen

    # Bin manipulation
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

    # Net tools
    ethtool

    # Audio & Video manipulation
    ffmpeg
    imagemagick
    waifu2x-converter-cpp

    # Android
    gitRepo
    simg2img

    # Emulation
    qemu

    # Encryption
    gnupg
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

    #######
    # Dev #
    #######
    
    # Shell
    bc
    shellcheck

    # C
    gcc
    cmake
    gnumake

    # Haskell
    ghc

    # JSON
    jq

    # Scripting general
    python
    nodejs
    yarn

    # Java
    adoptopenjdk-jre-bin

    #######

  ] ++ 
  mfunc.useDefault my.config.x86_64 [ flashrom ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [ ncpamixer ncspot playerctl ] [];

}
