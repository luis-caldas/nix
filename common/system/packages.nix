{ pkgs, ... }:
let
  my = import ../../config.nix;
in
{

  environment.systemPackages = with pkgs; [

    # System management packages
    wget
    vim
    tmux
    git
    bash
    tree
    w3m
    less

    # Some tools
    python

    # Shell scripting
    envsubst

    # Passwork hash generator
    mkpasswd

  ] ++ my.config.packages.system.normal;

}
