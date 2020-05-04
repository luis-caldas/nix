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

    # Bin manipulation
    hexedit
    binutils

    # Web tools
    w3m
    wget
    nmap
    bind

    # File manipulation
    tree
    file
    p7zip
    samba

    # Audio & Video manipulation
    ffmpeg
    imagemagick

    # Scripting general
    python

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
