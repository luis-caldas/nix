{ pkgs, ... }:
let
  configgo = import ../../config.nix;
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

    # Shell scripting
    envsubst

    # Passwork hash generator
    mkpasswd

  ] ++ configgo.packages.system.normal;

}
