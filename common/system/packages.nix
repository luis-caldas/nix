{ pkgs, ... }:
let
  my = import ../../config.nix;
  mfunc = import ../../functions/func.nix;
in
{

  environment.systemPackages = with pkgs; [

    # System management packages

    # Basic
    vim
    git
    tmux
    htop
    less
    screen

    # Bin manipulation
    hexedit
    binutils
    # flashrom # needs to be fixed for arm

    # Web tools
    w3m
    wget
    nmap
    bind

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

    # Scripting general
    python
    nodejs
    yarn

    # Dev
    adoptopenjdk-jre-bin

    # Android
    gitRepo
    simg2img

    # Emulation
    qemu

    # Encryption
    gnupg
    cryptsetup

    # Shell scripting
    bc
    envsubst

    # Passwork hash generator
    mkpasswd

  ] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [ ncpamixer ] [] ++
  my.config.packages.system.normal;

}
