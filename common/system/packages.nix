{ pkgs, ... }:
let
  my = import ../../config.nix;
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
    bash
    tree
    file
    less
    p7zip
    hexedit
    binutils

    # Some tools
    python

    # Shell scripting
    envsubst

    # Passwork hash generator
    mkpasswd

  ] ++ my.config.packages.system.normal;

}
