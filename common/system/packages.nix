{ pkgs, ... }:
let
  my = import ../../config.nix;
  mfunc = import ../../functions/func.nix;
in
{

  environment.systemPackages = with pkgs; [

    # System management packages
    bc
    vim
    git
    w3m
    tmux
    wget
    tree
    file
    less
    bind
    p7zip
    hexedit
    binutils

    # Some tools
    python

    # Shell scripting
    envsubst

    # Passwork hash generator
    mkpasswd

  ] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  my.config.packages.system.normal;

}
