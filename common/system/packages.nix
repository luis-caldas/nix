{ pkgs, ... }:
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

    # Shell scripting
    envsubst

    # Passwork hash generator
    mkpasswd

  ];

}
