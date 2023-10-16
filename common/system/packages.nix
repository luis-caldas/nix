{ pkgs, ... }:
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # Basic
    bc
    git
    tmux
    htop
    less
    gotop
    screen
    neovim
    nix-top
    nix-tree
    trash-cli

    # Network
    wget
    nmap
    socat
    tcpdump

    # Utils
    killall
    moreutils

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
